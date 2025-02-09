# ------------------------------------------------------------------------------
# Module: rds-aurora-cluster
# File: modules/rds-aurora-cluster/variables.tf
# Author: Kezie Iroha
# Description: Variables for RDS/Aurora Cluster with best practices
# ------------------------------------------------------------------------------

variable "vpc_details" {
  description = "VPC details including subnets, AZs, and security groups"
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

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "db_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "db_master_password" {
  description = "Master password for the database"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_engine" {
  description = "Database engine"
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_cluster_instance_count" {
  description = "Number of instances in the Aurora cluster"
  type        = number
  default     = 1
}

variable "db_cluster_identifier" {
  description = "Identifier for the database cluster"
  type        = string
  default     = "aurora-cluster-1"
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "02:00-03:00"
}

variable "db_preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:07:00-sun:08:00"
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "db_storage_encrypted" {
  description = "Enable encryption for database storage"
  type        = bool
  default     = true
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

variable "db_multi_az" {
  description = "Deploy RDS in Multi-AZ mode"
  type        = bool
  default     = false
}

variable "iam_role_arn" {
  description = "IAM Role ARN for database authentication"
  type        = string
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "deploy_aurora" {
  description = "Deploy an Aurora Cluster (true) or RDS instance (false)"
  type        = bool
  default     = true
}

variable "rds_deployment_type" {
  description = "Deployment type: 'aurora', 'multi_az_cluster', 'multi_az_instance', or 'single_instance'"
  type        = string
  validation {
    condition     = contains(["aurora", "multi_az_cluster", "multi_az_instance", "single_instance"], var.rds_deployment_type)
    error_message = "Valid options: 'aurora', 'multi_az_cluster', 'multi_az_instance', 'single_instance'."
  }
}

variable "db_parameter_group_family_aurora" {
  description = "Parameter group family for Aurora PostgreSQL"
  type        = string
  default     = "aurora-postgresql16"
}

variable "db_parameter_group_family_rds" {
  description = "Parameter group family for RDS PostgreSQL"
  type        = string
  default     = "postgres16"
}

variable "db_subnet_group_name" {
  description = "Name of the RDS subnet group"
  type        = string
  default     = "rds-subnet-group"
}

variable "max_connections" {
  description = "Maximum database connections"
  type        = number
  default     = 200
}

variable "db_parameter_group_name_aurora" {
  description = "Parameter group name for Aurora PostgreSQL"
  type        = string
  default     = "aurora-pg-parameter-group"
}

variable "db_parameter_group_name_rds" {
  description = "Parameter group name for RDS PostgreSQL"
  type        = string
  default     = "rds-pg-parameter-group"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before deleting the database"
  type        = bool
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "Lab"
}

variable "db_cluster_instance_class" {
  description = "Instance class for Multi-AZ RDS Cluster"
  type        = string
}
