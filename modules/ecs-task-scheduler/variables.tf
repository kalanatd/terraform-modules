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
  description = "VPC ID for ECS tasks and the spot instance (module does not create a VPC)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for Fargate tasks (awsvpc network)."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Optional: list of public subnets for spot instance (if instance needs a public IP)."
  default     = []
}

# ECR image (full URI or image:tag) - user provides this
variable "ecr_image" {
  type        = string
  description = "Full ECR image URI (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/myrepo:tag)"
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

# Spot GPU instance config
variable "spot_instance_type" {
  type        = string
  description = "GPU spot instance type (eg p3.2xlarge, g4dn.xlarge). Caller should ensure quota."
  default     = "g4dn.xlarge"
}

variable "spot_ami_id" {
  type        = string
  description = "AMI ID to use for the spot instance. If empty module will try to find an AMI (caller recommended to pass one)."
  default     = ""
}

variable "spot_key_name" {
  type        = string
  description = "Name of SSH key pair to attach to Spot instance (optional)."
  default     = ""
}

variable "spot_root_volume_size" {
  type        = number
  description = "Root EBS size in GB for the spot instance (persistent root volume)."
  default     = 200
}

variable "spot_subnet_id" {
  type        = string
  description = "Subnet ID to launch the spot instance into (public subnet if public IP required)."
  default     = ""
}

variable "spot_allocate_public_ip" {
  type        = bool
  description = "Whether to assign a public IP to the spot instance."
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

# Optional user_data for spot instance (bash)
variable "spot_user_data" {
  type        = string
  default     = ""
  description = "Optional user_data script to run on spot instance (base64 will be applied)."
}

# IAM settings
variable "create_ec2_instance_profile" {
  type    = bool
  default = true
  description = "Create EC2 instance profile and IAM role for spot instance. Set false to provide existing instance_profile_name."
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

