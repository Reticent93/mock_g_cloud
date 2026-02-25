#!/bin/bash
dnf update -y

# 1. Start Apache IMMEDIATELY so Health Checks pass
systemctl start httpd
systemctl enable httpd
echo "<h1>Initializing Infrastructure...</h1>" > /var/www/html/index.html

dnf update -y
# Install required packages for AL2023
dnf install -y httpd jq nmap-ncat amazon-cloudwatch-agent

# 2. Configure CloudWatch Agent
# Note: Use {instance_id} for CloudWatch variables, not bash variables
cat <<ETC > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "${project_name}-access-logs",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/tmp/db.test.log",
            "log_group_name": "${project_name}-db-test-logs",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
ETC

# 3. Start the Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 4. Database Secrets and Connectivity Test
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${db_secret_arn} --region ${aws_region} --query SecretString --output text)
DB_USER=$(echo $SECRET_JSON | jq -r .username)
DB_PASS=$(echo $SECRET_JSON | jq -r .password)

if nc -zv ${db_endpoint} 5432 -w 5 > /tmp/db.test.log 2>&1; then
  RESULT="SUCCESS: Connected to the database at ${db_endpoint}"
else
  RESULT="FAILURE: Could not reach the database. Check SGs!"
fi

# 5. Final Web Output
echo "<h1>Infrastructure Status</h1>" > /var/www/html/index.html
echo "<p>Project: ${project_name}</p>" >> /var/www/html/index.html
echo "<p>Database Connectivity: <strong>$RESULT</strong></p>" >> /var/www/html/index.html