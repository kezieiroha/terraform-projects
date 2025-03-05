# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/outputs.tf
# Author: Kezie Iroha
# Description: outputs for ec2 module - web and app tiers only
# ------------------------------------------------------------------------------

output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value = {
    web           = var.deploy_web_tier ? aws_instance.web[*].id : []
    app           = var.deploy_app_tier ? aws_instance.app[*].id : []
    web_duplicate = var.deploy_web_tier && var.deploy_alternate_az_set ? aws_instance.web_duplicate[*].id : []
    app_duplicate = var.deploy_app_tier && var.deploy_alternate_az_set ? aws_instance.app_duplicate[*].id : []
  }
}

output "public_ips" {
  description = "Public IPs of the created EC2 instances"
  value = {
    web           = var.deploy_web_tier ? aws_instance.web[*].public_ip : []
    web_duplicate = var.deploy_web_tier && var.deploy_alternate_az_set ? aws_instance.web_duplicate[*].public_ip : []
  }
}

output "private_ips" {
  description = "Private IPs of the created EC2 instances"
  value = {
    web           = var.deploy_web_tier ? aws_instance.web[*].private_ip : []
    app           = var.deploy_app_tier ? aws_instance.app[*].private_ip : []
    web_duplicate = var.deploy_web_tier && var.deploy_alternate_az_set ? aws_instance.web_duplicate[*].private_ip : []
    app_duplicate = var.deploy_app_tier && var.deploy_alternate_az_set ? aws_instance.app_duplicate[*].private_ip : []
  }
}

output "deployment_summary" {
  description = "Summary of what was deployed"
  value = {
    web_tier_deployed = var.deploy_web_tier
    app_tier_deployed = var.deploy_app_tier
    ha_deployed       = var.deploy_alternate_az_set
    total_instances = sum([
      var.deploy_web_tier ? 1 : 0,
      var.deploy_app_tier ? 1 : 0,
      var.deploy_web_tier && var.deploy_alternate_az_set ? 1 : 0,
      var.deploy_app_tier && var.deploy_alternate_az_set ? 1 : 0
    ])
  }
}
