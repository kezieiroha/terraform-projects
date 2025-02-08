# ------------------------------------------------------------------------------
# Module: rds-aurora-cluster
# File: modules/rds-aurora-cluster/main.tf
# Author: Kezie Iroha
# Description: main for rds-aurora-cluster module
# ------------------------------------------------------------------------------

# Subnet Group (Shared by Aurora & RDS)
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = var.vpc_details.subnets.private

  tags = {
    Name = "Aurora DB Subnet Group"
  }
}

# Parameter Group for Aurora with Best Practices
resource "aws_db_parameter_group" "aurora_pg" {
  count       = var.deploy_aurora ? 1 : 0
  name        = var.db_parameter_group_name_aurora
  family      = "aurora-postgresql16"
  description = "Parameter group for Aurora PostgreSQL"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
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
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  parameter {
    name  = "rds.enable_plan_management"
    value = "1"
  }

  parameter {
    name  = "rds.log_retention_period"
    value = "10080"
  }

  parameter {
    name  = "wal_level"
    value = "logical"
  }

  parameter {
    name  = "max_wal_senders"
    value = "10"
  }

  parameter {
    name  = "max_replication_slots"
    value = "10"
  }

  parameter {
    name  = "track_activity_query_size"
    value = "2048"
  }

  parameter {
    name  = "track_io_timing"
    value = "on"
  }
}

# Parameter Group for RDS PostgreSQL with Best Practices
resource "aws_db_parameter_group" "rds_pg" {
  count       = var.deploy_aurora ? 0 : 1
  name        = var.db_parameter_group_name_rds
  family      = "postgres16"
  description = "Parameter group for RDS PostgreSQL"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
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
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  parameter {
    name  = "rds.enable_plan_management"
    value = "1"
  }

  parameter {
    name  = "rds.log_retention_period"
    value = "10080"
  }

  parameter {
    name  = "wal_level"
    value = "logical"
  }

  parameter {
    name  = "max_wal_senders"
    value = "10"
  }

  parameter {
    name  = "max_replication_slots"
    value = "10"
  }

  parameter {
    name  = "track_activity_query_size"
    value = "2048"
  }

  parameter {
    name  = "track_io_timing"
    value = "on"
  }
}

# Deploy Aurora Cluster (if enabled)
resource "aws_rds_cluster" "aurora" {
  count              = var.deploy_aurora ? 1 : 0
  cluster_identifier = var.db_cluster_identifier
  engine             = "aurora-postgresql"
  engine_version     = var.db_engine_version
  database_name      = var.database_name
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  storage_encrypted  = true

  # PITR & Backups
  backup_retention_period      = 7
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:07:00-sun:08:00"

  # Security & Monitoring
  copy_tags_to_snapshot               = true
  enable_http_endpoint                = true
  deletion_protection                 = true
  iam_database_authentication_enabled = true

  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [var.vpc_details.security_groups.database]
  db_cluster_parameter_group_name = aws_db_parameter_group.aurora_pg[0].name
}

# Deploy RDS Instance (if Aurora is disabled)
resource "aws_db_instance" "rds" {
  count                 = var.deploy_aurora ? 0 : 1
  identifier            = "${var.db_cluster_identifier}-rds"
  engine                = "postgres"
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  # PITR & Backups
  backup_retention_period = 7

  # Security & Monitoring
  copy_tags_to_snapshot = true
  deletion_protection   = true

  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  parameter_group_name   = aws_db_parameter_group.rds_pg[0].name
}
