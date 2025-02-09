#!/bin/bash

# Aurora endpoint passed as an environment variable
AURORA_ENDPOINT=$(aws ssm get-parameter --name "/aurora/endpoint" --query "Parameter.Value" --output text)

echo "Generating IAM authentication token..."
export PGPASSWORD=$(aws rds generate-db-auth-token \
  --hostname "$AURORA_ENDPOINT" \
  --port 5432 \
  --region "us-east-1" \
  --username "iam_db_user")

echo "Connecting to Aurora PostgreSQL..."
psql "host=$AURORA_ENDPOINT user=iam_db_user dbname=auroradb sslmode=require" <<EOF
  CREATE ROLE iam_db_user WITH LOGIN;
  GRANT rds_iam TO iam_db_user;
EOF

echo "IAM authentication setup complete!"
