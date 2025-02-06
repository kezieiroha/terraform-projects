# ------------------------------------------------------------------------------
# Module: aurora-postgres
# File: modules/aurora-postgres/variables.tf
# Author: Kezie Iroha
# Description: variables for aurora-postgres module
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

variable "db_username" {
  description = "Username of the database"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Password of the database"
  type        = string
}
variable "db_master_username" {
  description = "Master username of the database"
  type        = string
  default     = "postgres"
}

variable "db_master_password" {
  description = "Master password of the database"
  type        = string
}

variable "db_port" {
  description = "Port of the database"
  type        = number
  default     = 5432
}

variable "db_engine" {
  description = "Engine of the database"
  type        = string
  default     = "aurora-postgresql"
}

variable "db_engine_version" {
  description = "Engine version of the database"
  type        = string
  default     = "14.6"
}

variable "db_instance_class" {
  description = "Instance class of the database"
  type        = string
  default     = "db.t3.medium"
}

variable "db_cluster_instance_count" {
  description = "Number of instances in the database cluster"
  type        = number
  default     = 1
}

variable "db_cluster_instance_identifier" {
  description = "Identifier of the database cluster instance"
  type        = string
  default     = "aurora-cluster-instance-1"
}

variable "db_cluster_identifier" {
  description = "Identifier of the database cluster"
  type        = string
  default     = "aurora-cluster-1"
}

variable "db_backup_retention_period" {
  description = "Backup retention period of the database"
  type        = number
  default     = 7
}

variable "db_preferred_backup_window" {
  description = "Preferred backup window of the database"
  type        = string
  default     = "02:00-03:00"
}

variable "db_preferred_maintenance_window" {
  description = "Preferred maintenance window of the database"
  type        = string
  default     = "sun:07:00-sun:08:00"
}

variable "db_publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Whether the database is protected from deletion"
  type        = bool
  default     = true
}

variable "db_storage_encrypted" {
  description = "Whether the database is encrypted"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final snapshot"
  type        = bool
  default     = true
}

variable "db_apply_immediately" {
  description = "Whether to apply changes immediately"
  type        = bool
  default     = true
}

variable "db_vpc_security_group_ids" {
  description = "List of VPC security groups to associate with the cluster"
  type        = list(string)
  default     = []
}

variable "db_tags" {
  description = "Tags to associate with the database"
  type        = map(string)
  default     = {}
}

variable "db_parameter_group_name" {
  description = "Name of the database parameter group"
  type        = string
  default     = "default.aurora-postgresql14"
}

variable "db_parameter_group_family" {
  description = "Family of the database parameter group"
  type        = string
  default     = "aurora-postgresql14"
}

variable "db_parameter_group_description" {
  description = "Description of the database parameter group"
  type        = string
  default     = "default.aurora-postgresql14 parameter group for aurora-postgres"
}

variable "db_parameter_group_parameters" {
  description = "Parameters of the database parameter group"
  type        = list(map(string))
  default = [
    {
      name  = "log_min_duration_statement"
      value = "250"
    }
  ]
}

variable "db_parameter_group_tags" {
  description = "Tags to associate with the database parameter group"
  type        = map(string)
  default     = {}
}

variable "db_availability_zones" {
  description = "Availability zones for the database"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_source_region" {
  description = "Source region for the database"
  type        = string
  default     = "us-east-1"
}

variable "db_global_cluster_identifier" {
  description = "Identifier of the global database cluster"
  type        = string
  default     = "global-db-cluster"
}

variable "db_source_db_cluster_identifier" {
  description = "Identifier of the source database cluster"
  type        = string
  default     = "aurora-cluster-1"
}

variable "db_enable_cross_region_read" {
  description = "Whether to enable cross region read"
  type        = bool
  default     = true
}

variable "db_enable_rds_proxy" {
  description = "Whether to enable RDS proxy"
  type        = bool
  default     = true
}

variable "aws_kms_key" {
  description = "KMS key to encrypt the RDS proxy"
  type        = string
  default     = "aws_rds"
}

variable "copy_tags_to_snapshot" {
  description = "Whether to copy tags to snapshot"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Identifier of the final snapshot"
  type        = string
  default     = "aurora-cluster-final-snapshot"
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot"
  type        = bool
  default     = true
}

variable "iam_roles" {
  description = "IAM roles to associate with the database"
  type        = list(string)
  default     = []
}

variable "iam_database_authentication_enabled" {
  description = "Whether to enable database authentication"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to cloudwatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "db_enable_http_endpoint" {
  description = "Whether to enable RDS proxy web access"
  type        = bool
  default     = true
}

variable "db_proxy_name" {
  description = "Name of the RDS proxy"
  type        = string
  default     = "aurora-db-proxy"
}
