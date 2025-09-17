# ECS Task Definitions for Application

# Frontend Task Definition
module "task_frontend" {
  source = "./modules/ecs_task_definition"

  family                   = "${var.PrefixCode}-frontend-task"
  cpu                      = "1024"
  memory                   = "2048"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_name  = "${var.PrefixCode}-frontend"
  container_image = "${module.ecr_frontend.repository_url}:latest"
  container_port  = 5000
  port_name       = "frontend-http"
  app_protocol    = "http"

  readonly_root_filesystem = true
  log_group                = "/aws/ecs/${var.PrefixCode}-frontend"

  volumes = [
    {
      name                     = "tmp-volume"
      efs_volume_configuration = null
    }
  ]

  mount_points = [
    {
      sourceVolume  = "tmp-volume"
      containerPath = "/tmp"
      readOnly      = false
    }
  ]
  environment_variables = [
    {
      name  = "PRIMARY_COLOR"
      value = "#532DB2"
    },
    {
      name  = "PRIMARY_HOVER"
      value = "#4521A3"
    },
    {
      name  = "PRIMARY_LIGHT"
      value = "rgba(83, 45, 178, 0.2)"
    },
    {
      name  = "PRIMARY_SHADOW"
      value = "rgba(83, 45, 178, 0.3)"
    }
  ]
}

# DataAPI Task Definition
module "task_dataapi" {
  source = "./modules/ecs_task_definition"

  family                   = "${var.PrefixCode}-dataapi-task"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_name  = "${var.PrefixCode}-dataapi"
  container_image = "${module.ecr_dataapi.repository_url}:latest"
  container_port  = 5000
  port_name       = "data-http"

  readonly_root_filesystem = true
  log_group                = "/aws/ecs/${var.PrefixCode}-dataapi"
}

# Alerts Task Definition
module "task_alerts" {
  source = "./modules/ecs_task_definition"

  family                   = "${var.PrefixCode}-alerts-task"
  cpu                      = "512"
  memory                   = "1536"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_name  = "${var.PrefixCode}-alerts"
  container_image = "${module.ecr_alerts.repository_url}:latest"
  container_port  = 5000
  port_name       = "alerts-http"

  readonly_root_filesystem = true
  log_group                = "/aws/ecs/${var.PrefixCode}-alerts"
}

# Media Task Definition (EC2)
module "task_media" {
  source = "./modules/ecs_task_definition"

  family                   = "${var.PrefixCode}-media-task"
  cpu                      = "512"
  memory                   = "512"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_name  = "${var.PrefixCode}-media"
  container_image = "${module.ecr_media.repository_url}:latest"
  container_port  = 5000
  port_name       = "media-http"
  # checkov:skip=CKV_AWS_336:Media service needs write access for temp files during S3 uploads
  readonly_root_filesystem = false

  log_group = "/aws/ecs/${var.PrefixCode}-media"

  # Environment variables for S3 image upload
  environment_variables = [
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    },
    {
      name  = "BUCKET_NAME"
      value = var.wildlife_s3_bucket_name
    }
  ]
}

# DataDB Task Definition (MongoDB with EFS)
module "task_datadb" {
  source = "./modules/ecs_task_definition"

  family                   = "${var.PrefixCode}-datadb-task"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_name  = "${var.PrefixCode}-datadb"
  container_image = "${module.ecr_datadb.repository_url}:latest"
  container_port  = 27017
  port_name       = "data-tcp"
  port_protocol   = "tcp"

  # checkov:skip=CKV_AWS_336:DataDB service runs MongoDB which requires write access to filesystem
  readonly_root_filesystem = false
  user                     = "0:0" # Run as root for MongoDB
  log_group                = "/aws/ecs/${var.PrefixCode}-datadb"

  # # EFS volume for MongoDB data persistence
  # volumes = [
  #   {
  #     name = "mongodb-data"
  #     efs_volume_configuration = {
  #       file_system_id = aws_efs_file_system.mongodb.id
  #       root_directory = "/"
  #     }
  #   }
  # ]

  # # Mount EFS volume to MongoDB data directory
  # mount_points = [
  #   {
  #     sourceVolume  = "mongodb-data"
  #     containerPath = "/data/db"
  #     readOnly      = false
  #   }
  # ]
}