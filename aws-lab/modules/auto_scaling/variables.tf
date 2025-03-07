# ------------------------------------------------------------------------------
# Module: auto_scaling
# File: modules/auto_scaling/variables.tf
# Author: Kezie Iroha
# Description: Variables for auto scaling module
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

variable "deploy_web_tier" {
  description = "Flag to deploy web tier auto scaling group"
  type        = bool
  default     = true
}

variable "deploy_app_tier" {
  description = "Flag to deploy app tier auto scaling group"
  type        = bool
  default     = true
}

variable "instance_types" {
  description = "Instance types for each tier"
  type = object({
    web = string
    app = string
  })
  default = {
    web = "t2.micro"
    app = "t2.micro"
  }
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = ""
}

variable "enable_ssh" {
  description = "Enable SSH access to instances"
  type        = bool
  default     = true
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for EC2 instances"
  type        = string
  default     = ""
}

variable "web_asg_config" {
  description = "Configuration for web tier auto scaling group"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 2
    max_size         = 4
    desired_capacity = 2
  }
}

variable "app_asg_config" {
  description = "Configuration for app tier auto scaling group"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 2
    max_size         = 4
    desired_capacity = 2
  }
}

variable "web_target_group_arn" {
  description = "ARN of web tier target group"
  type        = string
}

variable "app_target_group_arn" {
  description = "ARN of app tier target group"
  type        = string
}

variable "web_alb_arn" {
  description = "ARN of web tier ALB for scaling policy"
  type        = string
}

variable "app_alb_arn" {
  description = "ARN of app tier ALB for scaling policy"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "placement_group_name" {
  description = "Optional placement group name for instance distribution"
  type        = string
  default     = ""
}
