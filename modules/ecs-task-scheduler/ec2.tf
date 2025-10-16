# Security group for EC2 instance (spot or on-demand)
resource "aws_security_group" "ec2_sg" {
  count  = var.create_ec2_instance_profile ? 1 : 0
  name   = "${var.name}-ec2-sg"
  vpc_id = var.vpc_id
  description = "Security group for GPU ec2 instance"
  tags = var.tags

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # change for production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  chosen_subnet = var.ec2_subnet_id != "" ? var.ec2_subnet_id : (length(var.task_subnet_ids) > 0 ? var.task_subnet_ids[0] : var.private_subnet_ids[0])
}

#### EC2 Instances (no launch template)

# Request a persistent Spot instance (spot)
resource "aws_spot_instance_request" "gpu_spot" {
  count                       = var.create_ec2_instance_profile && var.ec2_purchase_option == "spot" ? 1 : 0
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name != "" ? var.ec2_key_name : null
  iam_instance_profile        = var.create_ec2_instance_profile ? aws_iam_instance_profile.ec2_instance_profile[0].name : var.instance_profile_name
  subnet_id                   = local.chosen_subnet
  vpc_security_group_ids      = [aws_security_group.ec2_sg[0].id]
  associate_public_ip_address = var.ec2_allocate_public_ip
  user_data                   = var.ec2_user_data != "" ? var.ec2_user_data : null
  spot_type                   = "one-time"
  wait_for_fulfillment        = true

  root_block_device {
    volume_size           = var.ec2_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Tag the Spot request itself
  tags = merge(var.tags, { Name = "${var.name}-spot-instance" })

}

# On-demand instance using the same launch template
resource "aws_instance" "ondemand" {
  count                       = var.create_ec2_instance_profile && var.ec2_purchase_option == "ondemand" ? 1 : 0
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name != "" ? var.ec2_key_name : null
  iam_instance_profile        = var.create_ec2_instance_profile ? aws_iam_instance_profile.ec2_instance_profile[0].name : var.instance_profile_name
  subnet_id                   = local.chosen_subnet
  vpc_security_group_ids      = [aws_security_group.ec2_sg[0].id]
  associate_public_ip_address = var.ec2_allocate_public_ip
  user_data                   = var.ec2_user_data != "" ? var.ec2_user_data : null

  root_block_device {
    volume_size           = var.ec2_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Tag EBS volumes created with this instance
  volume_tags = var.tags

  # Tag the instance
  tags = merge(var.tags, { Name = "${var.name}-ondemand-instance" })
}

# Export instance details
data "aws_instance" "spot_instance" {
  count       = var.create_ec2_instance_profile && var.ec2_purchase_option == "spot" ? 1 : 0
  depends_on  = [aws_spot_instance_request.gpu_spot]
  instance_id = aws_spot_instance_request.gpu_spot[0].spot_instance_id
}

data "aws_instance" "ondemand_instance" {
  count       = var.create_ec2_instance_profile && var.ec2_purchase_option == "ondemand" ? 1 : 0
  instance_id = aws_instance.ondemand[0].id
}
