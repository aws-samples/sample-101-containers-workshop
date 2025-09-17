# Creates ECS service with load balancer integration and service connect

# Get current AWS region
data "aws_region" "current" {}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count

  # Enable ECS Exec for container debugging
  enable_execute_command = var.enable_execute_command

  # Launch configuration - either launch_type or capacity_provider_strategy
  dynamic "capacity_provider_strategy" {
    for_each = length(var.capacity_provider_strategy) > 0 ? var.capacity_provider_strategy : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  # Use launch_type only if no capacity provider strategy is specified
  launch_type = length(var.capacity_provider_strategy) > 0 ? null : var.launch_type

  # Blue-green deployment (only for services without load balancers)
  # dynamic "deployment_configuration" {
  #   for_each = var.load_balancer_enabled ? [] : [1]
  #   content {
  #     strategy             = "BLUE_GREEN"
  #     bake_time_in_minutes = 1
  #   }
  # }

  # Network configuration
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  # Service Connect configuration
  dynamic "service_connect_configuration" {
    for_each = var.service_connect_enabled ? [1] : []
    content {
      enabled   = true
      namespace = var.service_connect_namespace_arn

      service {
        port_name      = var.service_connect_port_name
        discovery_name = var.service_connect_discovery_name

        client_alias {
          port = var.service_connect_port
        }
      }

      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-create-group"  = "true"
          "awslogs-group"         = "/aws/ecs/service-connect/wildlife-app"
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "wildlife"
        }
      }
    }
  }

  # Load balancer configuration (optional)
  dynamic "load_balancer" {
    for_each = var.load_balancer_enabled ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  tags = {
    Name         = var.service_name
    resourcetype = "compute"
    codeblock    = "ecs-service"
  }

  # Wait for service to reach steady state if requested
  wait_for_steady_state = var.wait_for_steady_state

  # Ignore changes to desired_count to allow Application Auto Scaling to manage it
  lifecycle {
    ignore_changes = [desired_count]
  }
}