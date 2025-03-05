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

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_details.subnets.public[0]
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 Bastion"
  }

  # Attach IAM Instance Profile if provided
  iam_instance_profile = var.iam_instance_profile

  # Enable SSM agent
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Only install basic packages during initial provisioning
  user_data = <<-EOF
    #!/bin/bash
    # Install required packages
    yum update -y
    yum install -y postgresql15 aws-cli jq
    
    # Create a welcome message
    cat > /home/ec2-user/welcome.txt << WELCOME
Welcome to the Bastion Host!

This server is configured to access PostgreSQL databases using IAM authentication.
After the database is fully provisioned, you'll be able to connect using the database endpoint.

For more information, check the AWS RDS documentation.
WELCOME

    echo "Basic setup complete."
  EOF
}

# Configure database access as a separate resource, using SSM for configuration
resource "null_resource" "configure_database_access" {
  triggers = {
    # Only trigger when endpoint changes and is not empty
    db_endpoint = var.db_endpoint != "" ? var.db_endpoint : "not-yet-available"
    instance_id = aws_instance.bastion.id
  }

  # This will only execute when var.db_endpoint is not empty
  provisioner "local-exec" {
    command = <<-EOT
      if [ "${var.db_endpoint}" != "" ]; then
        # Create the configuration script
        cat > /tmp/configure-db-access.sh << 'EOF'
#!/bin/bash
DB_ENDPOINT="${var.db_endpoint}"
REGION="${var.aws_region}"

# Store the endpoint in SSM Parameter Store
echo "Storing database endpoint in SSM: $DB_ENDPOINT"
aws ssm put-parameter \
  --name "/aurora/endpoint" \
  --value "$DB_ENDPOINT" \
  --type "String" \
  --overwrite

# Create a connection script for convenience
cat > /home/ec2-user/connect-db.sh << SCRIPT
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
SCRIPT

chmod +x /home/ec2-user/connect-db.sh
echo "Database access configuration complete."
EOF
        
        # Use AWS Systems Manager to run the script on the instance
        aws ssm send-command \
          --instance-ids "${aws_instance.bastion.id}" \
          --document-name "AWS-RunShellScript" \
          --parameters "commands=[\"bash -ex /tmp/configure-db-access.sh\"]" \
          --region "${var.aws_region}"
      else
        echo "Database endpoint not yet available. Skipping configuration."
      fi
    EOT
  }

  depends_on = [aws_instance.bastion]
}
