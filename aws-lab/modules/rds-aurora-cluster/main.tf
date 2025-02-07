# ------------------------------------------------------------------------------
# Module: rds-aurora-cluster
# File: modules/rds-aurora-cluster/main.tf
# Author: Kezie Iroha
# Description: main for rds-aurora-cluster module
# ------------------------------------------------------------------------------

# Deploy Parameter Group for Aurora
resource "aws_db_parameter_group" "aurora_pg" {
  count       = var.deploy_aurora ? 1 : 0
  name        = var.db_parameter_group_name_aurora
  family      = "aurora-postgresql16"
  description = "Parameter group for Aurora PostgreSQL"
}

# Deploy Parameter Group for RDS
resource "aws_db_parameter_group" "rds_pg" {
  count       = var.deploy_aurora ? 0 : 1
  name        = var.db_parameter_group_name_rds
  family      = "postgres16"
  description = "Parameter group for RDS PostgreSQL"
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

  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [var.vpc_details.security_groups.database]
  db_cluster_parameter_group_name = aws_db_parameter_group.aurora_pg[0].name
}

# Deploy RDS Instance (if Aurora is disabled)
resource "aws_db_instance" "rds" {
  count                  = var.deploy_aurora ? 0 : 1
  identifier             = "${var.db_cluster_identifier}-rds"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  parameter_group_name   = aws_db_parameter_group.rds_pg[0].name
}

