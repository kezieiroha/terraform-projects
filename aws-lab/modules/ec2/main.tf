# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/variables.tf
# Author: Kezie Iroha
# Description: main for ec2 module
# ------------------------------------------------------------------------------

data "aws_ami" "amazon-linux" {
  most_recent = true
  filter {
    name = "name"
    /* values = ["Amazon Linux 2023 AMI * x86_64 HVM kernel-*"] */
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon-linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.vpc_details.subnets.public_web.id
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  key_name               = var.key_name

  tags = {
    Name = "EC2 Web"
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon-linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.vpc_details.subnets.private_db.id
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  key_name               = var.key_name

  tags = {
    Name = "EC2 DB"
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon-linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.vpc_details.subnets.public_bastion.id
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.key_name

  tags = {
    Name = "EC2 Public Bastion"
  }
}

