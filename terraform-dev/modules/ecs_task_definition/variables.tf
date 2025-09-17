variable "family" {
  description = "Name of the task definition family"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Memory (MB) for the task"
  type        = string
  default     = "1024"
}

variable "requires_compatibilities" {
  description = "Launch type requirements (FARGATE, EC2)"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

variable "container_name" {
  description = "Name of the main container"
  type        = string
}

variable "container_image" {
  description = "Docker image for the main container"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 5000
}

variable "port_name" {
  description = "Name for the port mapping (for service connect)"
  type        = string
}

variable "port_protocol" {
  description = "Protocol for the port mapping"
  type        = string
  default     = "tcp"
}

variable "app_protocol" {
  description = "Application protocol (http, etc.)"
  type        = string
  default     = null
}

variable "readonly_root_filesystem" {
  description = "Whether the root filesystem is read-only"
  type        = bool
  default     = true
}

variable "user" {
  description = "User to run the container as (uid:gid)"
  type        = string
  default     = null
}

variable "log_group" {
  description = "CloudWatch log group name"
  type        = string
}

variable "volumes" {
  description = "List of volumes to attach to the task"
  type = list(object({
    name = string
    efs_volume_configuration = optional(object({
      file_system_id = string
      root_directory = optional(string, "/")
    }))
  }))
  default = []
}

variable "mount_points" {
  description = "List of mount points for the main container"
  type = list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = bool
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables for the main container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}