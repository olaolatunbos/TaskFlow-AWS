output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "security_group_id" {
  description = "ID of the ECS service's security group"
  value       = aws_security_group.this.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application, needed by the deploy pipeline"
  value       = aws_codedeploy_app.ecs.name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group, needed by the deploy pipeline"
  value       = aws_codedeploy_deployment_group.ecs.deployment_group_name
}
