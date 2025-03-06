# ------------------------------------------------------------------------------
# Module: bastion
# File: modules/bastion/main.tf
# Author: Kezie Iroha
# Description: main for bastion module
# ------------------------------------------------------------------------------

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

# Create a template file for the user data script
locals {
  environment_path = var.environment == "" ? "default" : var.environment

  # Create an encoded version of the endpoint to force replacement when it changes
  # This is a workaround for the lifecycle replace_triggered_by limitation
  db_endpoint_tag = var.db_endpoint == "" ? "no-endpoint" : var.db_endpoint

  # Enhanced user data script with expanded SSM parameter storage
  user_data_script = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    
    echo "Starting user data script execution: $(date)"
    
    # Install required packages
    echo "Installing packages..."
    yum update -y
    yum install -y postgresql15 aws-cli jq
    
    # Store important configuration in SSM Parameter Store
    echo "Storing configuration in SSM Parameter Store..."
    
    # Create parameter store hierarchy for this deployment
    aws ssm put-parameter \
      --name "/${local.environment_path}/infrastructure/version" \
      --value "1.0.0" \
      --type "String" \
      --overwrite
      
    aws ssm put-parameter \
      --name "/${local.environment_path}/database/engine" \
      --value "${var.db_engine}" \
      --type "String" \
      --overwrite
      
    aws ssm put-parameter \
      --name "/${local.environment_path}/database/endpoint" \
      --value "${var.db_endpoint}" \
      --type "String" \
      --overwrite
      
    aws ssm put-parameter \
      --name "/${local.environment_path}/database/port" \
      --value "5432" \
      --type "String" \
      --overwrite
      
    aws ssm put-parameter \
      --name "/${local.environment_path}/database/username" \
      --value "iam_db_user" \
      --type "String" \
      --overwrite
      
    aws ssm put-parameter \
      --name "/${local.environment_path}/bastion/instance_id" \
      --value "$INSTANCE_ID" \
      --type "String" \
      --overwrite
    
    # Create helper scripts for the EC2 user
    echo "Creating helper scripts..."
    
    # Create a welcome message
    cat > /home/ec2-user/welcome.txt << 'WELCOME'
Welcome to the Bastion Host!

This server is configured to access PostgreSQL databases using IAM authentication.
If your database is configured, you can connect using:
  /home/ec2-user/connect-db.sh

For more information, check the AWS RDS documentation.
WELCOME

    echo "Basic setup complete: $(date)" > /home/ec2-user/setup-log.txt
    
    # Create database connection script if endpoint is provided
    if [ "${var.db_endpoint}" != "" ]; then
      # Create database connection script
      cat > /home/ec2-user/connect-db.sh << 'SCRIPT'
#!/bin/bash
# Script to connect to PostgreSQL using IAM authentication

DB_ENDPOINT="${var.db_endpoint}"
REGION="${var.aws_region}"
USER="iam_db_user"
DATABASE="postgres"

echo "Generating authentication token..."
TOKEN=$(aws rds generate-db-auth-token \
  --hostname $DB_ENDPOINT \
  --port 5432 \
  --region $REGION \
  --username $USER)

echo "Connecting to PostgreSQL database..."
PGPASSWORD=$TOKEN psql "host=$DB_ENDPOINT user=$USER dbname=$DATABASE sslmode=require"
SCRIPT

      chmod +x /home/ec2-user/connect-db.sh
      
      echo "Database access configuration complete - endpoint: ${var.db_endpoint}" >> /home/ec2-user/setup-log.txt
    fi
    
    # Create a script to retrieve configuration from SSM
    cat > /home/ec2-user/get-config.sh << 'CONFIG_SCRIPT'
#!/bin/bash
# Script to retrieve configuration from SSM Parameter Store

ENVIRONMENT="${local.environment_path}"

echo "Infrastructure Configuration:"
aws ssm get-parameter --name "/$ENVIRONMENT/infrastructure/version" --query "Parameter.Value" --output text

echo -e "\nDatabase Configuration:"
aws ssm get-parameter --name "/$ENVIRONMENT/database/engine" --query "Parameter.Value" --output text
aws ssm get-parameter --name "/$ENVIRONMENT/database/endpoint" --query "Parameter.Value" --output text
aws ssm get-parameter --name "/$ENVIRONMENT/database/port" --query "Parameter.Value" --output text
CONFIG_SCRIPT

    chmod +x /home/ec2-user/get-config.sh
    
    echo "User data script completed: $(date)" >> /home/ec2-user/setup-log.txt
  EOF
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_details.subnets.public[0]
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name        = "EC2 Bastion"
    Environment = var.environment
    DBEndpoint  = local.db_endpoint_tag
  }

  # Attach IAM Instance Profile if provided
  iam_instance_profile = var.iam_instance_profile

  # User data to configure the instance
  user_data = local.user_data_script

  # Enable SSM agent
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# Create a simple file that shows if database config was included in user data
resource "local_file" "db_config_status" {
  content  = var.db_endpoint == "" ? "Database endpoint not provided during instance creation." : "Database endpoint (${var.db_endpoint}) was included in EC2 user_data."
  filename = "${path.module}/db_config_status.txt"
}
