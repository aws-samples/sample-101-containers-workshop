variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "launch_type" {
  description = "Launch type (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for EC2 launch type"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = []
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging containers"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign public IP to tasks"
  type        = bool
  default     = false
}

# Service Connect Configuration
variable "service_connect_enabled" {
  description = "Whether to enable Service Connect"
  type        = bool
  default     = true
}

variable "service_connect_namespace_arn" {
  description = "ARN of the Service Connect namespace"
  type        = string
}

variable "service_connect_port_name" {
  description = "Port name for Service Connect"
  type        = string
}

variable "service_connect_discovery_name" {
  description = "Discovery name for Service Connect"
  type        = string
}

variable "service_connect_port" {
  description = "Port for Service Connect client alias"
  type        = number
}

# Load Balancer Configuration (optional)
variable "load_balancer_enabled" {
  description = "Whether to attach a load balancer"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the target group (required if load_balancer_enabled is true)"
  type        = string
  default     = ""
}

variable "container_name" {
  description = "Name of the container for load balancer (required if load_balancer_enabled is true)"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port of the container for load balancer (required if load_balancer_enabled is true)"
  type        = number
  default     = 5000
}

# Deployment Configuration
variable "maximum_percent" {
  description = "Maximum percentage of tasks during deployment"
  type        = number
  default     = 200
}

variable "minimum_healthy_percent" {
  description = "Minimum healthy percentage of tasks during deployment"
  type        = number
  default     = 100
}

variable "wait_for_steady_state" {
  description = "Whether to wait for the service to reach a steady state"
  type        = bool
  default     = false
}