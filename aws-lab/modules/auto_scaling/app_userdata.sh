#!/bin/bash
# ------------------------------------------------------------------------------
# App Tier Auto Scaling Instance Setup Script
# Author: Kezie Iroha
# Description: Setup script for app tier instances in auto scaling group
# ------------------------------------------------------------------------------

# Update and install packages
yum update -y
yum install -y java-17-amazon-corretto tomcat tomcat-webapps tomcat-admin-webapps amazon-cloudwatch-agent

# Start and enable Tomcat
systemctl start tomcat
systemctl enable tomcat

# Configure Tomcat to listen on port 8080
sed -i 's/port="8080"/port="8080" address="0.0.0.0"/' /etc/tomcat/server.xml

# Create a simple health check endpoint
mkdir -p /var/lib/tomcat/webapps/ROOT
cat <<HTML > /var/lib/tomcat/webapps/ROOT/health
OK
HTML

# Restart Tomcat to apply changes
systemctl restart tomcat

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

echo "App tier setup completed at $(date)"