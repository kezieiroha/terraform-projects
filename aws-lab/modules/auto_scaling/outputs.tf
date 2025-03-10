# ----------------------------------------------
# Module: auto_scaling
# File: modules/auto_scaling/outputs.tf
# Author: Kezie Iroha  
# Description: Outputs for Auto Scaling module
# ---------------------------------------------- 

output "web_asg_id" {
  description = "ID of the web tier Auto Scaling Group"
  value       = var.deploy_web_tier ? aws_autoscaling_group.web_asg[0].id : null
}

output "web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  value       = var.deploy_web_tier ? aws_autoscaling_group.web_asg[0].name : null
}

output "web_asg_arn" {
  description = "ARN of the web tier Auto Scaling Group"
  value       = var.deploy_web_tier ? aws_autoscaling_group.web_asg[0].arn : null
}

output "app_asg_id" {
  description = "ID of the app tier Auto Scaling Group"
  value       = var.deploy_app_tier ? aws_autoscaling_group.app_asg[0].id : null
}

output "app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  value       = var.deploy_app_tier ? aws_autoscaling_group.app_asg[0].name : null
}

output "app_asg_arn" {
  description = "ARN of the app tier Auto Scaling Group"
  value       = var.deploy_app_tier ? aws_autoscaling_group.app_asg[0].arn : null
}

output "deployment_summary" {
  description = "Summary of what was deployed"
  value = {
    web_asg_deployed = var.deploy_web_tier
    app_asg_deployed = var.deploy_app_tier
    total_asgs       = sum([var.deploy_web_tier ? 1 : 0, var.deploy_app_tier ? 1 : 0])
    web_capacity = var.deploy_web_tier ? {
      min     = var.web_asg_config.min_size
      max     = var.web_asg_config.max_size
      desired = var.web_asg_config.desired_capacity
    } : null
    app_capacity = var.deploy_app_tier ? {
      min     = var.app_asg_config.min_size
      max     = var.app_asg_config.max_size
      desired = var.app_asg_config.desired_capacity
    } : null
  }
}
