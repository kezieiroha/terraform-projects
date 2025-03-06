# ------------------------------------------------------------------------------
# File: variables.tf
# Author: Kezie Iroha
# Description: Parent variables for project
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to be used for EC2 instances"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) == length(distinct(var.private_subnets))
    error_message = "Duplicate CIDR blocks detected in private_subnets. Please use unique CIDR ranges."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == length(distinct(var.public_subnets))
    error_message = "Duplicate CIDR blocks detected in public_subnets. Please use unique CIDR ranges."
  }
}

# EC2 Web/App Tier Variables
variable "deploy_ec2_tiers" {
  description = "Master flag to deploy EC2 web and app tiers"
  type        = bool
  default     = false
}

variable "ec2_az_overrides" {
  description = "Optional AZ override for each EC2 instance (web, app)"
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

variable "deploy_alternate_az_set" {
  description = "Flag to deploy an identical EC2 set in the alternate AZ"
  type        = bool
  default     = false
}

variable "instance_types" {
  description = "Instance types for each EC2 category"
  type = object({
    web     = string
    app     = string
    bastion = string
  })
  default = {
    web     = "t2.micro"
    app     = "t2.micro"
    bastion = "t2.micro"
  }
}

# Database Variables
variable "db_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "db_master_password" {
  description = "Master password for the database"
  type        = string
}

variable "db_instance_class" {
  description = "Instance class of the database"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "db_engine" {
  description = "Database engine"
  type        = string
}

variable "db_engine_version" {
  description = "Engine version of the database"
  type        = string
}

variable "db_cluster_instance_count" {
  description = "Number of instances in the database cluster"
  type        = number
}

variable "db_cluster_identifier" {
  description = "Identifier for the database cluster"
  type        = string
}

variable "iam_role_name" {
  description = "IAM role name for Aurora authentication"
  type        = string
  default     = "AuroraAuthRole"
}

variable "db_iam_user" {
  description = "IAM User for Aurora authentication"
  type        = string
}

variable "rds_deployment_type" {
  description = "Deployment type: 'aurora', 'multi_az_cluster', 'multi_az_instance', or 'single_instance'"
  type        = string
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before deleting the database"
  type        = bool
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance"
  type        = number
  default     = 50
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance"
  type        = number
  default     = 50
}

variable "db_cluster_instance_class" {
  description = "Instance class for Multi-AZ RDS Cluster"
  type        = string
  default     = "db.c6gd.medium"
}

# Bastion Variables
variable "enable_ssh" {
  description = "Enable SSH access to Bastion"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Enable AWS SSM Session Manager"
  type        = bool
  default     = true
}

# Keeping this variable for backward compatibility but it's not actually used
variable "private_key_path" {
  description = "Path to the private key file - Note: Not used with the new SSM approach"
  type        = string
  default     = ""
}

variable "db_parameter_group_family_rds" {
  description = "Parameter group family for RDS PostgreSQL"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to connect to bastion via SSH"
  type        = list(string)
  default     = []
}
