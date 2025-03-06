# ------------------------------------------------------------------------------
# Module: iam
# File: modules/iam/main.tf
# Author: Kezie Iroha
# Description: main for iam module with bastion host IAM resources
# ------------------------------------------------------------------------------

# Aurora Authentication Role
resource "aws_iam_role" "aurora_auth_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "rds.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "aurora_auth_policy" {
  name        = "${var.iam_role_name}-policy"
  description = "Allows IAM-based authentication to Aurora PostgreSQL"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "rds-db:connect"
      ],
      # More specific permission for the IAM user
      Resource = "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser/${var.db_cluster_identifier}/${var.db_iam_user}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aurora_auth_attach" {
  policy_arn = aws_iam_policy.aurora_auth_policy.arn
  role       = aws_iam_role.aurora_auth_role.name
}

# Bastion Host IAM Role for SSM and RDS access
resource "aws_iam_role" "bastion_role" {
  count = var.enable_bastion_iam ? 1 : 0
  name  = "BastionHostRole"

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

# SSM Policy for Bastion Host
resource "aws_iam_policy" "ssm_policy" {
  count       = var.enable_bastion_iam ? 1 : 0
  name        = "BastionSSMPolicy"
  description = "Allow bastion host to use SSM"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        Resource = "*"
      }
    ]
  })
}

# RDS Connect Policy for Bastion Host
resource "aws_iam_policy" "rds_connect_policy" {
  count       = var.enable_bastion_iam ? 1 : 0
  name        = "BastionRDSConnectPolicy"
  description = "Allow bastion host to connect to RDS using IAM authentication"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds-db:connect"
        ],
        Resource = "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser/${var.db_cluster_identifier}/${var.db_iam_user}"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach policies to Bastion role
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  count      = var.enable_bastion_iam ? 1 : 0
  policy_arn = aws_iam_policy.ssm_policy[0].arn
  role       = aws_iam_role.bastion_role[0].name
}

resource "aws_iam_role_policy_attachment" "rds_policy_attach" {
  count      = var.enable_bastion_iam ? 1 : 0
  policy_arn = aws_iam_policy.rds_connect_policy[0].arn
  role       = aws_iam_role.bastion_role[0].name
}

# Instance Profile for Bastion Host
resource "aws_iam_instance_profile" "bastion_profile" {
  count = var.enable_bastion_iam ? 1 : 0
  name  = "BastionHostProfile"
  role  = aws_iam_role.bastion_role[0].name
}
