#!/bin/bash

# Install required packages
echo "Installing PostgreSQL client and AWS CLI..."
sudo yum update -y
sudo yum install -y postgresql15 aws-cli jq

# Create a basic welcome message
cat > /home/ec2-user/welcome.txt << EOF
Welcome to the Bastion Host!

This server is configured to access PostgreSQL databases using IAM authentication.
After the database is fully provisioned, you'll be able to connect using:
  /home/ec2-user/connect-db.sh

For more information, check the AWS RDS documentation.
EOF

echo "Basic setup complete. The system will be configured for database access when the database is ready."