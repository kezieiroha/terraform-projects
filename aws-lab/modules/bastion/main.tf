# ------------------------------------------------------------------------------
# Module: bastion
# File: modules/bastion/main.tf
# Author: Kezie Iroha
# Description: main for bastion module
# ------------------------------------------------------------------------------

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# Generate the bastion setup script content
locals {
  bastion_setup_script = templatefile("${path.module}/bastion_setup.sh.tpl", {
    aws_region       = var.aws_region
    db_endpoint      = var.db_endpoint
    db_engine        = var.db_engine
    environment_path = var.environment == "" ? "default" : var.environment
    iam_user         = "iam_db_user" # Add this to the context
  })
}

# Write the script to a local file for reference (optional)
resource "local_file" "bastion_setup_script" {
  content  = local.bastion_setup_script
  filename = "${path.module}/bastion_setup.sh"
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_details.subnets.public[0]
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name        = "EC2 Bastion"
    Environment = var.environment
    DBEndpoint  = var.db_endpoint == "" ? "no-endpoint" : var.db_endpoint
  }

  # Attach IAM Instance Profile if provided
  iam_instance_profile = var.iam_instance_profile

  # User data to configure the instance
  user_data = local.bastion_setup_script

  # Enable SSM agent
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# Create a simple file that shows if database config was included in user data
resource "local_file" "db_config_status" {
  content  = var.db_endpoint == "" ? "Database endpoint not provided during instance creation." : "Database endpoint (${var.db_endpoint}) was included in EC2 user_data."
  filename = "${path.module}/db_config_status.txt"
}
