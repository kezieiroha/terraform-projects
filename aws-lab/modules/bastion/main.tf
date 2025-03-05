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

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_details.subnets.public[0]
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 Bastion"
  }

  # Attach IAM Instance Profile if provided
  iam_instance_profile = var.iam_instance_profile

  # Upload basic setup script
  provisioner "file" {
    source      = "${path.module}/setup-bastion.sh"
    destination = "/home/ec2-user/setup-bastion.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Execute script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/setup-bastion.sh",
      "/home/ec2-user/setup-bastion.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Enable SSM agent
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# Configure database access on the bastion after the database is available
resource "null_resource" "configure_database_access" {
  triggers = {
    # Only trigger when endpoint changes and is not empty
    db_endpoint = var.db_endpoint != "" ? var.db_endpoint : "not-yet-available"
  }

  # Make the provisioner itself conditional
  provisioner "file" {
    content = templatefile("${path.module}/configure-db-access.sh.tpl", {
      db_endpoint = var.db_endpoint,
      region      = var.aws_region
    })
    destination = "/home/ec2-user/configure-db-access.sh"

    # Only run when there's an endpoint
    on_failure = continue

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.bastion.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = var.db_endpoint != "" ? [
      "chmod +x /home/ec2-user/configure-db-access.sh",
      "/home/ec2-user/configure-db-access.sh"
    ] : ["echo 'Database endpoint not yet available'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.bastion.public_ip
    }
  }

  depends_on = [aws_instance.bastion]
}
