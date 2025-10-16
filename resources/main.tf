module "ecs_fargate_demo" {
  source = "../modules/ecs-task-scheduler"

  name                = "demo"
  vpc_id              = "vpc-0fefffbcfd060bc68"         # your VPC
  private_subnet_ids  = ["subnet-08851d6818d40a7de", "subnet-0d03e804190848a65"]
  public_subnet_ids   = ["subnet-0a695afe41b742aa6"]
  task_subnet_ids     = ["subnet-0a695afe41b742aa6"]

  # Public Docker Hub image
  container_image       = "985504043303.dkr.ecr.us-east-1.amazonaws.com/oho/log-anomaly:latest"

  # Run every 10 minutes for demo
  schedule_expression = "rate(10 minutes)"

  # Skip GPU for now (set to true later)
  create_ec2_instance_profile = true
  ec2_instance_type           = "t3.micro"
  ec2_purchase_option         = "spot"
  ec2_allocate_public_ip     = true
  ec2_ami_id                = "ami-0123456789abcdef0" # optional: provide your pre-configured AMI

  tags = {
    Environment = "poc"
    Owner       = "kalana"
    Name        = "oho-log-anomaly"
    project     = "oho"
    app         = "log-anomaly"
    organization = "oho"
  }
}
