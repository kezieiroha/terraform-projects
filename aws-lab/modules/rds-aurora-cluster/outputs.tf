# ------------------------------------------------------------------------------
# Module: rds-aurora-cluster
# File: modules/rds-aurora-cluster/outputs.tf
# Author: Kezie Iroha
# Description: outputs for rds-aurora-cluster module
# ------------------------------------------------------------------------------

output "aurora_cluster_id" {
  description = "The Aurora Cluster ID (if deployed)"
  value       = var.deploy_aurora ? aws_rds_cluster.aurora[0].id : null
}

output "rds_instance_id" {
  description = "The RDS Instance ID (if deployed)"
  value       = var.deploy_aurora ? null : aws_db_instance.rds[0].id
}

