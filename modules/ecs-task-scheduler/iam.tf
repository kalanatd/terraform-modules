# ECS Task Execution Role (for pulling ECR and writing logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name}-task-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for container to call AWS APIs)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_cloudwatch_read" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_ec2_read" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# EventBridge (CloudWatch Events) role to run ECS tasks
resource "aws_iam_role" "events_invoke_ecs" {
  name = "${var.name}-events-ecs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "events_invoke_ecs_policy" {
  name = "${var.name}-events-ecs-policy"
  role = aws_iam_role.events_invoke_ecs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:StartTask",
          "ecs:StopTask",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ec2:DescribeSubnets","ec2:DescribeNetworkInterfaces","ec2:DescribeSecurityGroups","ec2:CreateNetworkInterface","ec2:DeleteNetworkInterface"]
        Resource = "*"
      }
    ]
  })
}

# EC2 IAM Role & Instance Profile for ec2 instance (optional create)
resource "aws_iam_role" "ec2_instance_role" {
  count = var.create_ec2_instance_profile ? 1 : 0
  name  = "${var.name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  count      = var.create_ec2_instance_profile ? 1 : 0
  role       = aws_iam_role.ec2_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_attach" {
  count      = var.create_ec2_instance_profile ? 1 : 0
  role       = aws_iam_role.ec2_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  count = var.create_ec2_instance_profile ? 1 : 0
  name  = coalesce(var.instance_profile_name, "${var.name}-instance-profile")
  role  = aws_iam_role.ec2_instance_role[0].name
  tags  = var.tags
}
