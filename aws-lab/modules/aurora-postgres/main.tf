# ------------------------------------------------------------------------------
# Module: aurora-postgres
# File: modules/aurora-postgres/main.tf
# Author: Kezie Iroha
# Description: main for aurora-postgres module
# ------------------------------------------------------------------------------

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier = var.db_cluster_identifier
  engine             = "aurora-postgresql"
  engine_version     = var.db_engine_version
  availability_zones = var.vpc_details.availability_zones
  database_name      = var.database_name
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  storage_encrypted  = true

  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [var.vpc_details.security_groups.database]
  db_cluster_parameter_group_name = var.db_parameter_group_name

  backup_retention_period      = var.db_backup_retention_period
  preferred_backup_window      = var.db_preferred_backup_window
  preferred_maintenance_window = var.db_preferred_maintenance_window
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier
  skip_final_snapshot          = var.skip_final_snapshot

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  /*
  # Validate that iam auth is enabled before assignment 
  iam_roles = var.iam_database_authentication_enabled ? [
    {
      role_arn     = var.iam_role_arn
      feature_name = "rds_iam" # feature name for Aurora PostgreSQL IAM auth
    }
  ] : []
  }
  */

  #corrected version of the iam_roles configuration: https://aws.amazon.com/blogs/database/integrate-amazon-aurora-mysql-and-amazon-bedrock-using-sql/
  iam_roles = var.iam_database_authentication_enabled ? [var.iam_role_arn] : []

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = var.db_tags
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count                = var.db_cluster_instance_count
  identifier           = "${var.db_cluster_identifier}-instance-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.postgresql.id
  instance_class       = var.db_instance_class
  engine               = "aurora-postgresql"
  engine_version       = var.db_engine_version
  publicly_accessible  = var.db_publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = var.vpc_details.subnets.private

  tags = {
    Name = "Aurora DB Subnet Group"
  }
}
