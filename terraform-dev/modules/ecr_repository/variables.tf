variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for ECR encryption"
  type        = string
}