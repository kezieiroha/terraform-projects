# ------------------------------------------------------------------------------
# Module: kubernetes
# File: modules/kubernetes/main.tf
# Author: Kezie Iroha
# Description: main for kubernetes module
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1" # Change to preferred region
}

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

resource "aws_vpc" "k8s_lab" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "k8s_lab_vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.k8s_lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "public_subnet" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.k8s_lab.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "private_subnet" }
}

resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.k8s_lab.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow API server access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "k8s_security_group" }
}

resource "aws_iam_role" "k8s_role" {
  name = "k8s_instance_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "k8s_profile" {
  name = "k8s_profile"
  role = aws_iam_role.k8s_role.name
}

resource "aws_instance" "master" {
  ami                    = "ami-0c7217cdde317cfec" # RHEL 8 Free Tier
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_profile.name
  key_name               = "your-key" # Replace with your SSH key

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y docker kubeadm kubectl kubelet
  systemctl enable --now kubelet docker
  EOF

  tags = { Name = "k8s_master" }
}

resource "aws_instance" "worker" {
  ami                    = "ami-0c7217cdde317cfec" # RHEL 8 Free Tier
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_profile.name
  key_name               = "your-key" # Replace with your SSH key

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y docker kubeadm kubectl kubelet
  systemctl enable --now kubelet docker
  EOF

  tags = { Name = "k8s_worker" }
}

