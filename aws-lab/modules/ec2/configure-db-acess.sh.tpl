#!/bin/bash

# This script is generated from a Terraform template
# The database endpoint is passed from Terraform
DB_ENDPOINT="${db_endpoint}"
REGION="${region}"

# Store the endpoint in SSM Parameter Store
echo "Storing database endpoint in SSM: $DB_ENDPOINT"
aws ssm put-parameter \
  --name "/aurora/endpoint" \
  --value "$DB_ENDPOINT" \
  --type "String" \
  --overwrite

echo "Generating IAM authentication token..."
TOKEN=$(aws rds generate-db-auth-token \
  --hostname "$DB_ENDPOINT" \
  --port 5432 \
  --region "$REGION" \
  --username "iam_db_user")

# Create a connection script for convenience
cat > /home/ec2-user/connect-db.sh << EOF
#!/bin/bash
# Script to connect to PostgreSQL using IAM authentication

DB_ENDPOINT="$DB_ENDPOINT"
REGION="$REGION"
USER="iam_db_user"
DATABASE="postgres"

echo "Generating authentication token..."
TOKEN=\$(aws rds generate-db-auth-token \\
  --hostname \$DB_ENDPOINT \\
  --port 5432 \\
  --region \$REGION \\
  --username \$USER)

echo "Connecting to PostgreSQL database..."
PGPASSWORD=\$TOKEN psql "host=\$DB_ENDPOINT user=\$USER dbname=\$DATABASE sslmode=require"
EOF

chmod +x /home/ec2-user/connect-db.sh

echo "Database access configuration complete."
echo "Use /home/ec2-user/connect-db.sh to connect to the database via IAM authentication."