# Configure auto scaling for EC2 instances and media service to trigger capacity scaling

# Application Auto Scaling Target for Media Service (to trigger capacity scaling)
resource "aws_appautoscaling_target" "media" {
  max_capacity       = 6
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${module.service_media.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name         = "${var.PrefixCode}-media-scaling-target"
    resourcetype = "autoscaling"
    codeblock    = "capacity-scaling"
  }
}

# CPU-based Target Tracking Scaling Policy for Media Service (30% CPU target)
resource "aws_appautoscaling_policy" "media_cpu" {
  name               = "${var.PrefixCode}-media-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.media.resource_id
  scalable_dimension = aws_appautoscaling_target.media.scalable_dimension
  service_namespace  = aws_appautoscaling_target.media.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 30.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_out_cooldown = 300
    scale_in_cooldown  = 300
  }
}