#!/bin/bash
# ------------------------------------------------------------------------------
# Web Tier Auto Scaling Instance Setup Script
# Author: Kezie Iroha
# Description: Setup script for web tier instances in auto scaling group
# ------------------------------------------------------------------------------

# Install Apache for a basic web server
yum update -y
yum install -y httpd amazon-cloudwatch-agent

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple index page with instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Web Tier Instance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 30px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 800px;
            margin: 0 auto;
        }
        h1 {
            color: #0066cc;
        }
        .info {
            margin: 20px 0;
            padding: 15px;
            background-color: #e6f3ff;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Web Tier - Auto Scaling Group Instance</h1>
        <div class="info">
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>Environment:</strong> dev</p>
        </div>
    </div>
</body>
</html>
HTML

# Configure CloudWatch agent
cat <<JSON > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"],
        "ignore_file_system_types": ["sysfs", "devtmpfs"]
      },
      "mem": {
        "measurement": ["mem_used_percent"]
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    }
  }
}
JSON

# Start CloudWatch agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# Add a health check endpoint
cat <<HTML > /var/www/html/health
OK
HTML

echo "Web tier setup completed at $(date)"