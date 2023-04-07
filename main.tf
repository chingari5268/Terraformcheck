# Configure the AWS provider
provider "aws" {
  region = "eu-west-1"
}

# Define the list of agency names
variable "agencies" {
  type    = list(string)
  default = ["agency-a", "agency-b"]
}

# Create the SFTP server
resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = "PUBLIC"
  tags = {
    Name = "sftp-server"
  }
}

# Create the S3 bucket for each agency
resource "aws_s3_bucket" "agency_buckets" {
  count = length(var.agencies)
  bucket = "${var.agencies[count.index]}-bucket"
  acl    = "private"
  tags = {
    Name = "${var.agencies[count.index]}-bucket"
  }
}

# Create the IAM roles for each agency
resource "aws_iam_role" "agency_roles" {
  count = length(var.agencies)
  name  = "${var.agencies[count.index]}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

# Create the IAM policies for each agency
resource "aws_iam_policy" "agency_policies" {
  count = length(var.agencies)
  name  = "${var.agencies[count.index]}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.agency_buckets[count.index].arn}/*"
        ]
      }
    ]
  })
}

# Attach the IAM policies to the IAM roles for each agency
resource "aws_iam_role_policy_attachment" "agency_policy_attachments" {
  count           = length(var.agencies)
  policy_arn      = aws_iam_policy.agency_policies[count.index].arn
  role            = aws_iam_role.agency_roles[count.index].name
}

# Configure the SFTP server to use the S3 bucket as its root directory for each agency
resource "aws_transfer_user" "sftp_users" {
  count = length(var.agencies)
  server_id = aws_transfer_server.sftp.id
  username = "${var.agencies[count.index]}-user"
  home_directory = "/${var.agencies[count.index]}-bucket"
  home_directory_type = "S3"
  role = aws_iam_role.agency_roles[count.index].arn
  ssh_public_key_body = file("/home/ubuntu/key/Authentication")
}

# Output the values required to connect the SFTP users to the server
output "agency_sftp_server_id" {
  value = aws_transfer_server.sftp.id
}

output "agency_sftp_server_url" {
  value = aws_transfer_server.sftp.endpoint
}

output "login_command" {
  value = "sftp -i /path/to/key.pem ${aws_transfer_user.sftp_users.username}@${aws_transfer_server.sftp.endpoint}"
}

# Configure the CloudWatch metric alarm to monitor the S3 bucket for each agency
resource "aws_cloudwatch_metric_alarm" "missing_data_alarm" {
  count           = length(var.agencies)
  alarm_name      = "${var.agencies[count.index]}-missing-data-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 1
  metric_name     = "NumberOfObjects"
  namespace       = "AWS/S3"
  period          = 86400 # 24 hours
  statistic       = "Average"
  threshold       = 1
  alarm_description = "Alert if the number of objects in the S3 bucket for ${var.agencies[count.index]} is less than expected"
  alarm_actions   = [aws_sns_topic.incident_alerts.arn] # Replace with your SNS topic ARN for email notifications

  dimensions = {
    BucketName = aws_s3_bucket.agency_buckets[count.index].id
  }
}

# Create SNS topic for incident alerts
resource "aws_sns_topic" "incident_alerts" {
  name = "incident-alerts"
}

# Subscribe the SRE team email address to the SNS topic
resource "aws_sns_topic_subscription" "sre_email_subscription" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "email"
  endpoint  = "sre-team@example.com"
}

