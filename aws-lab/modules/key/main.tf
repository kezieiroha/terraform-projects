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

# Store the private key locally
resource "local_file" "private_key_file" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/generated-${var.key_name}.pem"
  file_permission = "0600"
}
