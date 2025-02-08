# ------------------------------------------------------------------------------
# Module: rds-aurora-cluster
# File: modules/rds-aurora-cluster/main.tf
# Author: Kezie Iroha
# Description: Main Terraform module for deploying RDS/Aurora PostgreSQL with best practices
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Local Variables for Derived Parameters
# ------------------------------------------------------------------------------
locals {
  # Approximate RAM per instance size (in MB)
  instance_ram = {
    "db.t3.micro"    = 1024
    "db.t3.small"    = 2048
    "db.t3.medium"   = 4096
    "db.t3.large"    = 8192
    "db.t3.xlarge"   = 16384
    "db.t3.2xlarge"  = 32768
    "db.r6g.large"   = 16384
    "db.r6g.xlarge"  = 32768
    "db.r6g.2xlarge" = 65536
  }

  # Get RAM for the selected instance type
  total_memory_mb = lookup(local.instance_ram, var.db_instance_class, 4096) # Default to 4GB if unknown

  # Derived PostgreSQL memory settings
  shared_buffers       = floor(local.total_memory_mb * 0.25)                      # 25% of total memory
  effective_cache_size = floor(local.total_memory_mb * 0.5)                       # 50% of total memory
  work_mem             = floor(local.total_memory_mb / (var.max_connections / 4)) # Divide by connections

  # Aurora vs. RDS Specific Values
  random_page_cost = var.deploy_aurora ? 1.1 : 2.0
}

# ------------------------------------------------------------------------------
# Subnet Group (Uses Shared VPC Module)
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.db_subnet_group_name
  subnet_ids = var.vpc_details.subnets.private

  tags = {
    Name = var.db_subnet_group_name
  }
}

# ------------------------------------------------------------------------------
# Parameter Group for Aurora PostgreSQL
# ------------------------------------------------------------------------------

resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  count       = var.deploy_aurora ? 1 : 0
  name        = var.db_parameter_group_name_aurora
  family      = var.db_parameter_group_family_aurora
  description = "Best practices parameter group for Aurora PostgreSQL"

  parameter {
    name  = "log_connections"
    value = "1"
  }
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  parameter {
    name  = "log_statement"
    value = "ddl"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "250"
  }
  parameter {
    name         = "shared_buffers"
    value        = tostring(local.shared_buffers)
    apply_method = "pending-reboot" # Static parameter
  }
  parameter {
    name         = "effective_cache_size"
    value        = tostring(local.effective_cache_size)
    apply_method = "pending-reboot" # Static parameter
  }
  parameter {
    name         = "work_mem"
    value        = tostring(local.work_mem)
    apply_method = "immediate" # Dynamic parameter
  }
  parameter {
    name         = "random_page_cost"
    value        = tostring(local.random_page_cost)
    apply_method = "immediate" # Dynamic parameter
  }
}

# ------------------------------------------------------------------------------
# Parameter Group for RDS PostgreSQL
# ------------------------------------------------------------------------------
resource "aws_rds_cluster_parameter_group" "rds_pg" {
  count       = var.deploy_aurora ? 0 : 1
  name        = var.db_parameter_group_name_rds
  family      = var.db_parameter_group_family_rds
  description = "Best practices parameter group for RDS PostgreSQL"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  parameter {
    name  = "password_encryption"
    value = "scram-sha-256"
  }
  parameter {
    name  = "log_connections"
    value = "1"
  }
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  parameter {
    name  = "log_statement"
    value = "ddl"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "250"
  }
  parameter {
    name  = "shared_buffers"
    value = tostring(local.shared_buffers)
  }
  parameter {
    name  = "effective_cache_size"
    value = tostring(local.effective_cache_size)
  }
  parameter {
    name  = "work_mem"
    value = tostring(local.work_mem)
  }
  parameter {
    name  = "random_page_cost"
    value = tostring(local.random_page_cost)
  }
  parameter {
    name  = "wal_level"
    value = "replica"
  }
  parameter {
    name  = "max_wal_senders"
    value = "10"
  }
  parameter {
    name  = "checkpoint_completion_target"
    value = "0.9"
  }
  parameter {
    name  = "wal_compression"
    value = "on"
  }
}

# ------------------------------------------------------------------------------
# Deploy Aurora Cluster (If `deploy_aurora` is True)
# ------------------------------------------------------------------------------
resource "aws_rds_cluster" "aurora" {
  count                               = var.deploy_aurora ? 1 : 0
  cluster_identifier                  = var.db_cluster_identifier
  engine                              = var.db_engine
  engine_version                      = var.db_engine_version
  database_name                       = var.database_name
  master_username                     = var.db_master_username
  master_password                     = var.db_master_password
  storage_encrypted                   = true
  deletion_protection                 = var.db_deletion_protection
  iam_database_authentication_enabled = true

  backup_retention_period      = var.db_backup_retention_period
  preferred_backup_window      = var.db_preferred_backup_window
  preferred_maintenance_window = var.db_preferred_maintenance_window

  db_subnet_group_name            = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids          = [var.vpc_details.security_groups.database]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg[0].name
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "${var.db_cluster_identifier}-final-snapshot"


  # Ensure the parameter group is created before the cluster
  depends_on = [aws_rds_cluster_parameter_group.aurora_pg]

}

# ------------------------------------------------------------------------------
# Deploy Multi-AZ RDS Instance (if `rds_deployment_type == "multi_az_cluster"`)
# ------------------------------------------------------------------------------
resource "aws_rds_cluster" "multi_az_cluster" {
  count              = var.deploy_aurora ? 0 : (var.rds_deployment_type == "multi_az_cluster" ? 1 : 0)
  cluster_identifier = "${var.db_cluster_identifier}-multi-az"
  engine             = var.db_engine
  engine_version     = var.db_engine_version
  database_name      = var.database_name
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  storage_encrypted  = true

  backup_retention_period      = var.db_backup_retention_period
  preferred_backup_window      = var.db_preferred_backup_window
  preferred_maintenance_window = var.db_preferred_maintenance_window

  db_subnet_group_name            = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids          = [var.vpc_details.security_groups.database]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds_pg[0].name
}

# ------------------------------------------------------------------------------
# Deploy Multi-AZ RDS Instance (if `rds_deployment_type == "multi_az_instance"`)
# ------------------------------------------------------------------------------
resource "aws_db_instance" "multi_az_instance" {
  count                 = var.deploy_aurora ? 0 : (var.rds_deployment_type == "multi_az_instance" ? 1 : 0)
  identifier            = "${var.db_cluster_identifier}-multi-az-instance"
  engine                = var.db_engine
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true
  multi_az              = true
  deletion_protection   = var.db_deletion_protection

  backup_retention_period = var.db_backup_retention_period

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
}

# ------------------------------------------------------------------------------
# Deploy Single RDS Instance (if `rds_deployment_type == "single_instance"`)
# ------------------------------------------------------------------------------
resource "aws_db_instance" "single_instance" {
  count                 = var.deploy_aurora ? 0 : (var.rds_deployment_type == "single_instance" ? 1 : 0)
  identifier            = "${var.db_cluster_identifier}-single-instance"
  engine                = var.db_engine
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true

  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
}

