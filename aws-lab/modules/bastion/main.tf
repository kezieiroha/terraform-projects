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

  # Attach IAM Role if SSM is enabled
  iam_instance_profile = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

  # Upload IAM Auth setup script
  provisioner "file" {
    source      = "${path.module}/setup-aurora-iam.sh"
    destination = "/home/ec2-user/setup-aurora-iam.sh"
  }

  # Execute script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/setup-aurora-iam.sh",
      "/home/ec2-user/setup-aurora-iam.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  # Enable SSM agent if SSM is enabled
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# IAM Role for SSM if enabled
resource "aws_iam_role" "ssm_role" {
  count = var.enable_ssm ? 1 : 0
  name  = "BastionSSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for SSM Session Manager
resource "aws_iam_policy_attachment" "ssm_policy_attach" {
  count      = var.enable_ssm ? 1 : 0
  name       = "BastionSSMPolicyAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  roles      = [aws_iam_role.ssm_role[0].name]
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0
  name  = "BastionSSMProfile"
  role  = aws_iam_role.ssm_role[0].name
}
