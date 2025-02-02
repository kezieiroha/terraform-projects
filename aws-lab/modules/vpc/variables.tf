# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/variables.tf
# Author: Kezie Iroha
# Description: variables for vpc module
# ------------------------------------------------------------------------------

/*
variable "aws_region" {
  description = "AWS region where VPC will be created"
  type        = string
  default     = "us-east-1" # Change as needed
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "kezie-lab-vpc"
}

variable "public_web_subnet_cidr" {
  description = "CIDR block for the public web subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_bastion_subnet_cidr" {
  description = "Name of the public bastion subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_app_subnet_cidr" {
  description = "CIDR block for the private app subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_db_subnet_cidr" {
  description = "Name of the private app subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "public_bastion_az" {
  description = "Availability zone for the public bastion subnet"
  type        = string
  default     = "us-east-1a" # Change as needed
}

variable "public_web_az" {
  description = "Availability zone for the public web subnet"
  type        = string
  default     = "us-east-1a" # Change as needed
}

variable "private_app_az" {
  description = "Availability zone for the private app subnet"
  type        = string
  default     = "us-east-1a" # Change as needed
}

variable "private_db_az" {
  description = "Availability zone for the private db subnet"
  type        = string
  default     = "us-east-1a" # Change as needed
}

variable "internet_gateway" {
  description = "Name of the internet gateway"
  type        = string
  default     = "kezie-lab-igw"
}
*/

variable "deployment_regions" {
  description = "Map of regions with VPC, AZ, and subnet configurations"
  type = map(object({
    vpc_cidr_block     = string
    availability_zones = optional(list(string))
    az_count           = optional(number)
    private_subnets    = list(string)
    public_subnets     = list(string)
  }))

  validation {
    condition     = length(var.deployment_regions) > 0
    error_message = <<EOT
You must specify at least one region in 'deployment_regions'.
Specify one or more regions like this:
deployment_regions = {
  "us-east-1" = {
    vpc_cidr_block     = "10.0.0.0/16"
    az_count           = 2
    private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets     = ["10.0.3.0/24", "10.0.4.0/24"]
  },
  "eu-west-1" = {
    vpc_cidr_block     = "10.1.0.0/16"
    availability_zones = ["eu-west-1a", "eu-west-1b"]
    private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
    public_subnets     = ["10.1.3.0/24", "10.1.4.0/24"]
  }
}
EOT
  }
}
