# Creates ECS task definition with container configuration and logging

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecs_task_definition" "task" {
# checkov:skip=CKV_AWS_336: Some services require write access - Media service needs temp files for S3 uploads, DataDB service runs MongoDB requiring write access. Frontend/Alerts services use readonly where possible.
  family                   = var.family
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  # Dynamic volumes
  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id     = efs_volume_configuration.value.file_system_id
          root_directory     = efs_volume_configuration.value.root_directory
          transit_encryption = "ENABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name                   = var.container_name
      image                  = var.container_image
      essential              = true
      readonlyRootFilesystem = var.readonly_root_filesystem
      user                   = var.user

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = var.port_protocol
          name          = var.port_name
          appProtocol   = var.app_protocol
        }
      ]

      # Dynamic mount points
      mountPoints = var.mount_points

      # Environment variables with X-Ray daemon address
      environment = concat(
        var.environment_variables,
        [
          {
            name  = "AWS_XRAY_DAEMON_ADDRESS"
            value = "localhost:2000"
          }
        ]
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group"  = "true"
          "awslogs-group"         = var.log_group
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }

      dependsOn = [
        {
          containerName = "aws-xray-daemon"
          condition     = "START"
        }
      ]
    },
    {
      name      = "aws-xray-daemon"
      image     = "public.ecr.aws/xray/aws-xray-daemon:latest"
      essential = true

      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group"  = "true"
          "awslogs-group"         = "/aws/ecs/xray-daemon"
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name         = var.family
    resourcetype = "compute"
    codeblock    = "ecs-task-definition"
  }
}