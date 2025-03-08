# ------------------------------------------------------------------------------
# Module: auto_scaling
# File: modules/auto_scaling/variables.tf
# Author: Kezie Iroha (compatible version)
# Description: Variables for Auto Scaling module
# ------------------------------------------------------------------------------

variable "key_name" {
  description = "Name of the SSH key pair to use with instances"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_details" {
  description = "Details of the VPC"
  type = object({
    vpc_id   = string
    vpc_cidr = string
    igw_id   = string
    nat_id   = string
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

variable "deploy_web_tier" {
  description = "Flag to deploy web tier EC2 instances"
  type        = bool
  default     = true
}

variable "deploy_app_tier" {
  description = "Flag to deploy app tier EC2 instances"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "instance_types" {
  description = "Instance types for each EC2 category"
  type = object({
    web = string
    app = string
  })
  default = {
    web = "t2.micro"
    app = "t2.micro"
  }
}

variable "enable_ssh" {
  description = "Enable SSH access to instances"
  type        = bool
  default     = true
}

variable "web_asg_config" {
  description = "Web tier Auto Scaling Group configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 1
    max_size         = 3
    desired_capacity = 2
  }
}

variable "app_asg_config" {
  description = "App tier Auto Scaling Group configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 1
    max_size         = 3
    desired_capacity = 2
  }
}

variable "web_alb_arn" {
  description = "ARN of the web tier ALB"
  type        = string
  default     = ""
}

variable "web_target_group_arn" {
  description = "ARN of the web tier target group"
  type        = string
  default     = ""
}

variable "app_alb_arn" {
  description = "ARN of the app tier ALB"
  type        = string
  default     = ""
}

variable "app_target_group_arn" {
  description = "ARN of the app tier target group"
  type        = string
  default     = ""
}
