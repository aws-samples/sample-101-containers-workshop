# Terraform Variables - only the variables actually used by CodeBuild
# CodeBuild passes: -var="PrefixCode=${PrefixCode}" -var="Region=${AWS::Region}"

# Core Infrastructure Parameters (passed by CodeBuild)
variable "PrefixCode" {
  description = "Resource naming prefix for uniqueness and organization"
  type        = string
  default     = "wildlife"
}

variable "Region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

# Wildlife Application Specific
variable "wildlife_s3_bucket_name" {
  description = "Name of the existing S3 bucket for wildlife images"
  type        = string
  default     = "wildlife-bucket-placeholder"
}

variable "logs_s3_bucket_name" {
  description = "Name of the existing S3 bucket for access logs"
  type        = string
  default     = "logs-bucket-placeholder"
}