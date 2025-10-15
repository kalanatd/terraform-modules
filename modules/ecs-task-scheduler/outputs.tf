output "ecs_cluster_id" {
  description = "ECS cluster id"
  value       = aws_ecs_cluster.this.id
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.scheduled.arn
}

output "schedule_rule_arn" {
  description = "EventBridge schedule rule ARN"
  value       = aws_cloudwatch_event_rule.schedule.arn
}

output "spot_instance_id" {
  description = "Spot instance ID"
  value       = length(aws_spot_instance_request.gpu_spot) > 0 ? aws_spot_instance_request.gpu_spot[0].spot_instance_id : (length(aws_instance.ondemand) > 0 ? aws_instance.ondemand[0].id : "")
}

output "spot_instance_public_ip" {
  description = "Public IP of spot instance if assigned (may be empty)"
  value       = length(data.aws_instance.spot_instance) > 0 ? data.aws_instance.spot_instance[0].public_ip : (length(data.aws_instance.ondemand_instance) > 0 ? data.aws_instance.ondemand_instance[0].public_ip : "")
}

output "task_security_group_id" {
  description = "Security group id used for the Fargate task"
  value       = length(var.task_security_group_ids) > 0 ? var.task_security_group_ids : [aws_security_group.task_sg[0].id]
}
