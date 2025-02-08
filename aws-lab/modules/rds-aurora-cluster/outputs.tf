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

output "rds_cluster_id" {
  description = "The Multi-AZ DB Cluster ID (if deployed)"
  value       = var.deploy_aurora ? null : (var.rds_deployment_type == "multi_az_cluster" ? aws_rds_cluster.multi_az_cluster[0].id : null)
}

output "rds_instance_id" {
  description = "The Single DB or Multi-AZ DB Instance ID (if deployed)"
  value = var.deploy_aurora ? null : (
    var.rds_deployment_type == "single_instance" ? aws_db_instance.single_instance[0].id :
    var.rds_deployment_type == "multi_az_instance" ? aws_db_instance.multi_az_instance[0].id : null
  )
}

output "db_cluster_identifier" {
  description = "The cluster identifier of the deployed RDS/Aurora instance"
  value = (
    var.deploy_aurora ? aws_rds_cluster.aurora[0].cluster_identifier :
    var.rds_deployment_type == "multi_az_cluster" ? aws_rds_cluster.multi_az_cluster[0].cluster_identifier :
    var.rds_deployment_type == "multi_az_instance" ? aws_db_instance.multi_az_instance[0].identifier :
    aws_db_instance.single_instance[0].identifier
  )
}
