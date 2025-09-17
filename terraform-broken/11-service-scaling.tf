# Configure auto scaling for the frontend service based on CPU utilization

# Application Auto Scaling Target for Frontend Service
resource "aws_appautoscaling_target" "frontend" {
  max_capacity       = 2
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${module.service_frontend.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name         = "${var.PrefixCode}-frontend-scaling-target"
    resourcetype = "autoscaling"
    codeblock    = "service-scaling"
  }
}

# CPU-based Target Tracking Scaling Policy
resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "${var.PrefixCode}-frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 100.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_out_cooldown = 300
    scale_in_cooldown  = 300
  }
}