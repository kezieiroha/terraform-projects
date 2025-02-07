# ------------------------------------------------------------------------------
# Module: aurora-postgres
# File: modules/aurora-postgres/outputs.tf
# Author: Kezie Iroha
# Description: outputs for aurora-postgres module
# ------------------------------------------------------------------------------

output "aurora_cluster_id" {
  description = "The Aurora Cluster ID"
  value       = aws_rds_cluster.postgresql.id
}

output "aurora_cluster_endpoint" {
  description = "Aurora Cluster Endpoint"
  value       = aws_rds_cluster.postgresql.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora Reader Endpoint"
  value       = aws_rds_cluster.postgresql.reader_endpoint
}

output "aurora_instance_endpoints" {
  description = "Endpoints of each Aurora instance"
  value       = aws_rds_cluster_instance.aurora_instances[*].endpoint
}
