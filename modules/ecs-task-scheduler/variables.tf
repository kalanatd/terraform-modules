variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "Name prefix for resources"
  default     = "ecs-fargate"
}

# Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID for ECS tasks and the ec2 instance (module does not create a VPC)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for Fargate tasks (awsvpc network)."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Optional: list of public subnets for ec2 instance (if instance needs a public IP)."
  default     = []
}

# Container image - supports both ECR and Docker Hub
variable "container_image" {
  type        = string
  description = "Container image URI. Supports ECR (123456789012.dkr.ecr.us-east-1.amazonaws.com/myrepo:tag) or Docker Hub (nginx:latest)"
}

variable "container_name" {
  type        = string
  default     = "scheduled-container"
}

# Fargate sizing
variable "fargate_cpu" {
  type    = number
  default = 512
  description = "Task CPU for Fargate task"
}

variable "fargate_memory" {
  type    = number
  default = 1024
  description = "Task memory (MB) for Fargate task"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Container port for task (if exposed)."
}

# Schedule
variable "schedule_expression" {
  type        = string
  description = "EventBridge schedule expression (cron(...) or rate(...))"
  default     = "rate(1 day)"
}

variable "task_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs where the Fargate task will run (must be in same VPC)"
  default     = []
}

variable "task_security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the Fargate task (awsvpc). If empty module will create one."
  default     = []
}

# Whether to assign a public IP to the Fargate task ENI. Set true when using
# public subnets and no NAT is available, so the task can reach the internet
# (e.g., to pull images from Docker Hub). Keep false for private subnets with NAT.
variable "task_assign_public_ip" {
  type        = bool
  description = "Assign public IP to Fargate task network interface (requires public subnets)."
  default     = true
}

# ECS cluster config
variable "cluster_name" {
  type        = string
  description = "Name for ECS cluster"
  default     = null
}

# General EC2 instance config (applies to both spot and on-demand)
variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for the helper instance (e.g., t3.micro, g4dn.xlarge)."
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  type        = string
  description = "AMI ID to use for the EC2 instance (spot or on-demand). If empty the module will try to find an ECS-optimized AMI."
  default     = ""
}

variable "ec2_key_name" {
  type        = string
  description = "Name of SSH key pair to attach to the EC2 instance (optional)."
  default     = ""
}

variable "ec2_root_volume_size" {
  type        = number
  description = "Root EBS size in GB for the ec2 instance (persistent root volume)."
  default     = 200
}

variable "ec2_subnet_id" {
  type        = string
  description = "Subnet ID to launch the ec2 instance into (public subnet if public IP required)."
  default     = ""
}

variable "ec2_allocate_public_ip" {
  type        = bool
  description = "Whether to assign a public IP to the ec2 instance."
  default     = false
}

variable "instance_profile_name" {
  type        = string
  default     = null
  description = "Optional: existing instance profile name to use for the spot instance; if empty module will create one."
}

# Tags
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources."
}

# Optional user_data for ec2 instance (bash)
variable "ec2_user_data" {
  type        = string
  default     = ""
  description = "Optional user_data script to run on ec2 instance (base64 will be applied)."
}

# IAM settings
variable "create_ec2_instance_profile" {
  type    = bool
  default = true
  description = "Create EC2 instance profile and IAM role for ec2 instance. Set false to provide existing instance_profile_name."
}

# EC2 purchase option selection
variable "ec2_purchase_option" {
  type        = string
  default     = "spot"
  description = "EC2 purchase option: 'spot' for persistent spot, 'ondemand' for on-demand instance."
  validation {
    condition     = contains(["spot", "ondemand"], var.ec2_purchase_option)
    error_message = "ec2_purchase_option must be 'spot' or 'ondemand'."
  }
}

variable "ec2_subnet_id" {
  type        = string
  description = "Subnet ID for the EC2 instance. If empty, uses the first of task_subnet_ids or private_subnet_ids."
  default     = ""
}