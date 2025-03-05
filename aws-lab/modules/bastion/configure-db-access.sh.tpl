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

# Create a helper script to set up the IAM user in the database
cat > /home/ec2-user/setup-db-user.sh << EOF
#!/bin/bash
# Script to set up the IAM user in the database

DB_ENDPOINT="$DB_ENDPOINT"
REGION="$REGION"
MASTER_USER="postgres"
DATABASE="postgres"

# Note: You will need to provide the master password when prompted
echo "Connecting as master user to set up IAM authentication..."
echo "Please enter the master password when prompted."

psql "host=\$DB_ENDPOINT user=\$MASTER_USER dbname=\$DATABASE sslmode=require" << PSQL
  -- Create the IAM user role if it doesn't exist
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'iam_db_user') THEN
      CREATE ROLE iam_db_user WITH LOGIN;
    END IF;
  END
  \$\$;

  -- Grant the rds_iam role to the user
  GRANT rds_iam TO iam_db_user;
  
  -- Create a test database for the user
  CREATE DATABASE iam_db_user_db WITH OWNER iam_db_user;
  
  -- Grant additional permissions as needed
  GRANT ALL PRIVILEGES ON DATABASE iam_db_user_db TO iam_db_user;
PSQL

echo "IAM user setup complete. You can now connect using IAM authentication."
EOF

chmod +x /home/ec2-user/setup-db-user.sh

echo "Database access configuration complete."
echo "Use /home/ec2-user/connect-db.sh to connect to the database via IAM authentication."
echo "Use /home/ec2-user/setup-db-user.sh to set up the IAM user in the database (requires master password)."