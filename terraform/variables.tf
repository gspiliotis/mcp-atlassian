# AWS Configuration
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "mcp-atlassian"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}

# Networking
variable "vpc_id" {
  description = "VPC ID where the service will be deployed"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID with NAT gateway for ECS tasks and NLB"
  type        = string
}

# Route53
variable "route53_zone_id" {
  description = "Route53 private hosted zone ID"
  type        = string
}

variable "hostname" {
  description = "Hostname for the service in the private zone (e.g., atlassian-mcp.mydomain.net)"
  type        = string
}

# Service Configuration
variable "service_name" {
  description = "Name of the ECS service and related resources"
  type        = string
  default     = "mcp-atlassian"
}

variable "service_port" {
  description = "Port exposed by the Network Load Balancer"
  type        = number
  default     = 9000
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 9000
}

# Container Configuration
variable "container_image" {
  description = "Container image from GHCR"
  type        = string
  default     = "ghcr.io/sooperset/mcp-atlassian"
}

variable "container_image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "container_command" {
  description = "Command to run in the container (MCP server with HTTP transport)"
  type        = list(string)
  default = [
    "--transport",
    "streamable-http",
    "--port",
    "9000",
    "-vv"
  ]
}

variable "environment_variables" {
  description = "Environment variables for the container. Note: Users provide authentication via HTTP headers."
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "MCP_VERBOSE"
      value = "true"
    },
    {
      name  = "MCP_LOGGING_STDOUT"
      value = "true"
    },
    {
      name  = "ATLASSIAN_OAUTH_ENABLE"
      value = "true"
    }
  ]
}

# ECS Task Configuration
variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

# Auto Scaling
variable "enable_autoscaling" {
  description = "Enable auto-scaling for the ECS service"
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks when autoscaling is enabled"
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks when autoscaling is enabled"
  type        = number
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for autoscaling"
  type        = number
  default     = 80
}

# PrivateLink Configuration
variable "privatelink_acceptance_required" {
  description = "Whether acceptance is required for VPC endpoint connections"
  type        = bool
  default     = false
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Feature Flags
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

variable "enable_bedrock_permissions" {
  description = "Enable Bedrock API permissions for ECS tasks"
  type        = bool
  default     = false
}
