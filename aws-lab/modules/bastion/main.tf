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
  db_access_script = var.db_endpoint == "" ? "" : <<-EOF
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
  
  # Store the endpoint in SSM Parameter Store (for potential future use)
  aws ssm put-parameter \
    --name "/aurora/endpoint" \
    --value "${var.db_endpoint}" \
    --type "String" \
    --overwrite || true
  
  echo "Database access configuration complete - endpoint: ${var.db_endpoint}" >> /home/ec2-user/setup-log.txt
  EOF

  # Create an encoded version of the endpoint to force replacement when it changes
  # This is a workaround for the lifecycle replace_triggered_by limitation
  db_endpoint_tag = var.db_endpoint == "" ? "no-endpoint" : var.db_endpoint
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_details.subnets.public[0]
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 Bastion"
    # This tag will force the instance to be replaced when the endpoint changes
    DBEndpoint = local.db_endpoint_tag
  }

  # Attach IAM Instance Profile if provided
  iam_instance_profile = var.iam_instance_profile

  # User data to configure the instance
  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    
    echo "Starting user data script execution: $(date)"
    
    # Install required packages
    echo "Installing packages..."
    yum update -y
    yum install -y postgresql15 aws-cli jq
    
    # Create a welcome message
    cat > /home/ec2-user/welcome.txt << 'WELCOME'
Welcome to the Bastion Host!

This server is configured to access PostgreSQL databases using IAM authentication.
If your database is configured, you can connect using:
  /home/ec2-user/connect-db.sh

For more information, check the AWS RDS documentation.
WELCOME

    echo "Basic setup complete: $(date)" > /home/ec2-user/setup-log.txt
    
    ${local.db_access_script}
    
    echo "User data script completed: $(date)" >> /home/ec2-user/setup-log.txt
  EOF

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
