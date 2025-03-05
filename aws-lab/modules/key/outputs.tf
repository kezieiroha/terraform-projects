# ------------------------------------------------------------------------------
# Module: key
# File: modules/key/outputs.tf
# Author: Kezie Iroha
# Description: outputs for key module
# ------------------------------------------------------------------------------

output "key_name" {
  description = "Name of the generated key pair"
  value       = aws_key_pair.generated_key.key_name
}

output "key_pair_id" {
  description = "The ID of the generated key pair"
  value       = aws_key_pair.generated_key.id
}

output "private_key_pem" {
  description = "The private key in PEM format"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "public_key_openssh" {
  description = "The public key in OpenSSH format"
  value       = tls_private_key.ssh_key.public_key_openssh
}

output "private_key_path" {
  description = "Path to the stored private key file"
  value       = local_file.private_key_file.filename
}
