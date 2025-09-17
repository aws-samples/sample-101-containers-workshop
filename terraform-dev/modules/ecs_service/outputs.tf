output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}