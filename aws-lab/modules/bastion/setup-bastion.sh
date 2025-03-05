#!/bin/bash

# Install required packages
echo "Installing PostgreSQL client and AWS CLI..."
sudo yum install -y postgresql15 aws-cli jq

echo "Basic setup complete. The system will be configured for database access when the database is ready."