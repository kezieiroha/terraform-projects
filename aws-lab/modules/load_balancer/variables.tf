# ------------------------------------------------------------------------------
# Module: load_balancer
# File: modules/load_balancer/variables.tf
# Author: Kezie Iroha
# Description: Variables for load balancer module
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_details" {
  description = "VPC details including security groups and subnets"
  type = object({
    vpc_id   = string
    vpc_cidr = string
    subnets = object({
      public  = list(string)
      private = list(string)
    })
    security_groups = object({
      web      = string
      app      = string
      database = string
      bastion  = string
    })
    availability_zones = list(string)
  })
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancers"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable access logs for load balancers"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (required if enable_access_logs is true)"
  type        = string
  default     = ""
}

variable "web_health_check_path" {
  description = "Health check path for web tier target group"
  type        = string
  default     = "/"
}

variable "app_health_check_path" {
  description = "Health check path for app tier target group"
  type        = string
  default     = "/health"
}

variable "enable_https" {
  description = "Enable HTTPS listener for web ALB"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listener (required if enable_https is true)"
  type        = string
  default     = ""
}
