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
TOKEN=\$(aws rds generate-db-auth-token \\
  --hostname $DB_ENDPOINT \\
  --port 5432 \\
  --region $REGION \\
  --username iam_db_user)

PGPASSWORD=\$TOKEN psql "host=$DB_ENDPOINT user=iam_db_user dbname=postgres sslmode=require"
EOF

chmod +x /home/ec2-user/connect-db.sh

echo "Database access configured. You can connect using: /home/ec2-user/connect-db.sh"