resource "aws_ecs_cluster" "this" {
  name = var.cluster_name != null ? var.cluster_name : "${var.name}-cluster"
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/ecs/${aws_ecs_cluster.this.name}/${var.container_name}"
  retention_in_days = 14
  tags              = var.tags
}

# Security group for the task if not provided
resource "aws_security_group" "task_sg" {
  count  = 1
  name   = "${var.name}-task-sg"
  vpc_id = var.vpc_id
  description = "Security group for ECS Fargate scheduled task"
  revoke_rules_on_delete = true
  tags = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow ECS task SG to access EC2 instance SG (all traffic by default; scope as needed)
resource "aws_security_group_rule" "ecs_to_ec2" {
  count                    = var.create_ec2_instance_profile ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.ec2_sg[0].id
  source_security_group_id = aws_security_group.task_sg[0].id
}

# Task definition for FARGATE
data "aws_iam_policy_document" "exec_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_task_definition" "scheduled" {
  family                   = "${var.name}-scheduled"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.fargate_cpu)
  memory                   = tostring(var.fargate_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      cpu       = var.fargate_cpu
      memory    = var.fargate_memory
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = var.container_name
        }
      }
    }
  ])

  tags = var.tags
}

data "aws_region" "current" {}

# EventBridge rule (schedule)
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.name}-schedule"
  schedule_expression = var.schedule_expression
  state               = "ENABLED"
  tags                = var.tags
}

# EventBridge target to run ECS task
resource "aws_cloudwatch_event_target" "run_task" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_ecs_cluster.this.arn

  role_arn = aws_iam_role.events_invoke_ecs.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.scheduled.arn
    task_count          = 1
    launch_type         = "FARGATE"

    network_configuration {
      subnets         = var.task_subnet_ids
      security_groups = [aws_security_group.task_sg[0].id]
      assign_public_ip = var.task_assign_public_ip
    }
  }
}
