# ------------------------------------------------------------------------------
# Module: key
# File: modules/key/main.tf
# Author: Kezie Iroha
# Description: main for key module - implements SSH key pair generation
# ------------------------------------------------------------------------------

# Generate a new private key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the AWS key pair using the public key from the generated private key
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Store the private key locally if requested
resource "local_file" "private_key_file" {
  count           = var.store_locally ? 1 : 0
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/generated-${var.key_name}.pem"
  file_permission = "0600"
}

# Store the private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "ssh_key" {
  count       = var.store_in_secrets_manager ? 1 : 0
  name        = "ssh/${var.key_name}/private-key"
  description = "SSH private key for ${var.key_name}"
}

resource "aws_secretsmanager_secret_version" "ssh_key" {
  count         = var.store_in_secrets_manager ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ssh_key[0].id
  secret_string = tls_private_key.ssh_key.private_key_pem
}
