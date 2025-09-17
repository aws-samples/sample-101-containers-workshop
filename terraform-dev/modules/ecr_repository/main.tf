# Creates ECR repository with lifecycle policy and encryption

# Get default KMS key for ECR encryption
data "aws_kms_key" "default" {
  key_id = "alias/aws/ecr"
}

resource "aws_ecr_repository" "repo" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name         = var.name
    resourcetype = "container"
    codeblock    = "ecr-repository"
  }
}

# ECR Lifecycle Policy - Clean up old images
resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images after one day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}