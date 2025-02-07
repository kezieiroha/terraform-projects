# ------------------------------------------------------------------------------
# Module: iam
# File: modules/iam/main.tf
# Author: Kezie Iroha
# Description: main for iam module
# ------------------------------------------------------------------------------

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
      # Apply for all users
      Resource = "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser/${var.db_cluster_identifier}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aurora_auth_attach" {
  policy_arn = aws_iam_policy.aurora_auth_policy.arn
  role       = aws_iam_role.aurora_auth_role.name
}
