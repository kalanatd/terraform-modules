# Security group for Spot instance
resource "aws_security_group" "spot_sg" {
  name   = "${var.name}-spot-sg"
  vpc_id = var.vpc_id
  description = "Security group for GPU Spot instance"
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

# Optional: data to lookup a default AMI if user didn't pass spot_ami_id.
data "aws_ami" "default" {
  count = var.spot_ami_id == "" ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"] # ECS optimized Amazon Linux 2 - adjust if GPU AMI needed
  }

  owners = ["amazon"]
}

locals {
  chosen_ami = var.spot_ami_id != "" ? var.spot_ami_id : (length(data.aws_ami.default) > 0 ? data.aws_ami.default[0].id : "")
}

# Launch Template for the spot instance
resource "aws_launch_template" "spot" {
  name_prefix   = "${var.name}-spot-lt-"
  image_id      = local.chosen_ami
  instance_type = var.spot_instance_type
  key_name      = var.spot_key_name != "" ? var.spot_key_name : null

  iam_instance_profile {
    name = var.create_ec2_instance_profile ? aws_iam_instance_profile.ec2_instance_profile[0].name : var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = var.spot_allocate_public_ip ? true : false
    security_groups             = [aws_security_group.spot_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = var.spot_root_volume_size
      volume_type           = "gp3"
    }
  }

  user_data = var.spot_user_data != "" ? base64encode(var.spot_user_data) : null

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${var.name}-spot-instance" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Request a persistent Spot instance (spot request - persistent)
resource "aws_spot_instance_request" "gpu_spot" {
  count                   = 1
  launch_group            = "${var.name}-spot-group"
  launch_template {
    id      = aws_launch_template.spot.id
    version = "$Latest"
  }
  spot_type               = "persistent"
  wait_for_fulfillment    = true
  tags = merge(var.tags, { Name = "${var.name}-spot-instance" })
}

# Export instance details
data "aws_instance" "spot_instance" {
  depends_on = [aws_spot_instance_request.gpu_spot]
  instance_id = aws_spot_instance_request.gpu_spot.instance_id
}
