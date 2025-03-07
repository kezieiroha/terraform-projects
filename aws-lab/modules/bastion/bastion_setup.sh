#!/bin/bash
# ------------------------------------------------------------------------------
# Bastion Host Setup Script
# Author: Kezie Iroha
# Description: Comprehensive setup for database access via IAM authentication
# ------------------------------------------------------------------------------

# Enable verbose logging to file and console
exec > >(tee /var/log/bastion-setup.log|logger -t bastion-setup -s 2>/dev/console) 2>&1

echo "===== Starting Bastion Host Setup: $(date) ====="

# System updates and package installation
echo "Installing required packages..."
yum update -y
yum install -y postgresql15 aws-cli jq git vim tmux htop

# Store the instance ID and region
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION="us-east-1"
DB_ENDPOINT="rds-db-single-instance.cv244s608wpb.us-east-1.rds.amazonaws.com:5432"
DB_ENGINE="postgres"
IAM_USER="iam_db_user"

# Configure SSM Parameter Store with environment structure
echo "Configuring environment in SSM Parameter Store..."
ENV_PATH="/dev"

# Create or update critical parameters
echo "Storing configuration in SSM Parameter Store..."
aws ssm put-parameter --name "$ENV_PATH/bastion/instance_id" --value "$INSTANCE_ID" --type "String" --overwrite
aws ssm put-parameter --name "$ENV_PATH/bastion/setup_time" --value "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --type "String" --overwrite

# Database configuration in SSM (if provided)
if [ -n "$DB_ENDPOINT" ]; then
  echo "Storing database configuration in SSM..."
  aws ssm put-parameter --name "$ENV_PATH/database/endpoint" --value "$DB_ENDPOINT" --type "String" --overwrite
  aws ssm put-parameter --name "$ENV_PATH/database/engine" --value "$DB_ENGINE" --type "String" --overwrite
  aws ssm put-parameter --name "$ENV_PATH/database/port" --value "5432" --type "String" --overwrite
  aws ssm put-parameter --name "$ENV_PATH/database/iam_user" --value "$IAM_USER" --type "String" --overwrite
fi

# Create helpful utility scripts for the EC2 user
echo "Creating utility scripts..."

# 1. Welcome message
cat > /home/ec2-user/welcome.txt << 'WELCOME'
===================================================
  Welcome to the PostgreSQL Database Bastion Host
===================================================

This server is configured to access PostgreSQL databases using IAM authentication.

Available scripts:
  * connect-db.sh - Connect to the PostgreSQL database using IAM auth
  * get-config.sh - Display the current environment configuration
  * update-db-user.sh - Update database IAM user configuration (requires master password)

For more information, check the AWS RDS documentation.
WELCOME

# 2. Database connection script (if endpoint provided)
if [ -n "$DB_ENDPOINT" ]; then
  cat > /home/ec2-user/connect-db.sh << CONNECT
#!/bin/bash
# Script to connect to PostgreSQL using IAM authentication

DB_ENDPOINT="$DB_ENDPOINT"
REGION="$REGION"
USER="$IAM_USER"
DATABASE="postgres"

echo "Generating authentication token..."
TOKEN=\$(aws rds generate-db-auth-token \\
  --hostname \$DB_ENDPOINT \\
  --port 5432 \\
  --region \$REGION \\
  --username \$USER)

echo "Connecting to PostgreSQL database..."
PGPASSWORD=\$TOKEN psql "host=\$DB_ENDPOINT user=\$USER dbname=\$DATABASE sslmode=require"
CONNECT

  chmod +x /home/ec2-user/connect-db.sh
  
  # 3. Script to set up the IAM user in the database
  cat > /home/ec2-user/update-db-user.sh << SETUP
#!/bin/bash
# Script to set up the IAM user in the database

DB_ENDPOINT="$DB_ENDPOINT"
REGION="$REGION"
MASTER_USER="postgres"
DATABASE="postgres"
IAM_USER="$IAM_USER"

# Note: You will need to provide the master password when prompted
echo "Connecting as master user to set up IAM authentication..."
echo "Please enter the master password when prompted."

psql "host=\$DB_ENDPOINT user=\$MASTER_USER dbname=\$DATABASE sslmode=require" << PSQL
  -- Create the IAM user role if it doesn't exist
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '\$IAM_USER') THEN
      CREATE ROLE \$IAM_USER WITH LOGIN;
    END IF;
  END
  \$\$;

  -- Grant the rds_iam role to the user
  GRANT rds_iam TO \$IAM_USER;
  
  -- Create a test database for the user
  CREATE DATABASE \$IAM_USER_db WITH OWNER \$IAM_USER;
  
  -- Grant additional permissions as needed
  GRANT ALL PRIVILEGES ON DATABASE \$IAM_USER_db TO \$IAM_USER;
PSQL

echo "IAM user setup complete. You can now connect using IAM authentication."
SETUP

  chmod +x /home/ec2-user/update-db-user.sh
fi

# 4. Configuration retrieval script
cat > /home/ec2-user/get-config.sh << CONFIG
#!/bin/bash
# Script to display the current environment configuration

ENV_PATH="dev"
REGION="$REGION"

echo "===== Environment Configuration: \$ENV_PATH ====="

echo -e "\nBastion Host Information:"
echo "Instance ID: \$INSTANCE_ID"
echo "Region: \$REGION"
echo "Setup Time: \$(aws ssm get-parameter --name "/\$ENV_PATH/bastion/setup_time" --query "Parameter.Value" --output text)"

if [ -n "\$DB_ENDPOINT" ]; then
  echo -e "\nDatabase Configuration:"
  echo "Engine: \$DB_ENGINE"
  echo "Endpoint: \$DB_ENDPOINT"
  echo "Port: 5432"
  echo "IAM User: $IAM_USER"
else
  echo -e "\nNo database currently configured."
fi

echo -e "\nFor more detailed configuration, check the SSM Parameter Store:"
echo "aws ssm get-parameters-by-path --path \"/\$ENV_PATH\" --recursive"
CONFIG

chmod +x /home/ec2-user/get-config.sh

# Add helpful aliases to .bashrc
cat >> /home/ec2-user/.bashrc << 'BASHRC'

# PostgreSQL shortcuts
alias pg-connect='~/connect-db.sh'
alias pg-config='~/get-config.sh'
alias pg-setup='~/update-db-user.sh'

# Display welcome message on login
cat ~/welcome.txt
BASHRC

# Set proper permissions
chown ec2-user:ec2-user /home/ec2-user/*.sh
chown ec2-user:ec2-user /home/ec2-user/welcome.txt

echo "===== Bastion Host Setup Complete: $(date) ====="
echo "Connection information:"
if [ -n "$DB_ENDPOINT" ]; then
  echo "Database endpoint: $DB_ENDPOINT"
else
  echo "Database endpoint: Not configured"
fi

# Clean up any temporary files
rm -f /tmp/setup-*.tmp