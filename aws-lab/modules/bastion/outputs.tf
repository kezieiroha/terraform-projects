# ------------------------------------------------------------------------------
# Module: bastion
# File: modules/bastion/outputs.tf
# Author: Kezie Iroha
# Description: outputs for bastion module
# ------------------------------------------------------------------------------

output "bastion_instance_id" {
  description = "ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_availability_zone" {
  description = "Availability zone of the bastion host"
  value       = aws_instance.bastion.availability_zone
}

output "connection_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.bastion.public_ip}"
}
