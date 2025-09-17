# ECR Repositories for Application

# Get KMS key for ECR encryption
data "aws_kms_key" "default" {
  key_id = "alias/aws/ecr"
}

# Frontend service repository
module "ecr_frontend" {
  source      = "./modules/ecr_repository"
  name        = "${var.PrefixCode}/frontend"
  kms_key_arn = data.aws_kms_key.default.arn
}

# Data API service repository
# TODO: Add the dataapi service repository

# Alerts service repository
# TODO: Add the alerts service repository

# Media service repository - MISSING!
# TODO: Add the media service repository

# Database service repository
module "ecr_datadb" {
  source      = "./modules/ecs_service"
  name        = "${var.PrefixCode}/datadb"
  kms_key_arn = data.aws_kms_key.default.arn
}