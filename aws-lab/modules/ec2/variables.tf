# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/variables.tf
# Author: Kezie Iroha
# Description: variables for ec2 module - web and app tiers only
# ------------------------------------------------------------------------------

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

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = ""
}

variable "deploy_alternate_az_set" {
  description = "Flag to deploy identical EC2 set in an alternate AZ"
  type        = bool
  default     = false
}

variable "ec2_az_overrides" {
  description = "Availability Zone overrides for EC2 instances"
  type = object({
    web = optional(string)
    app = optional(string)
  })
  default = {}
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
