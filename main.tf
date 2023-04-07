# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create the S3 bucket for the agency
resource "aws_s3_bucket" "agency_bucket" {
  bucket = "myagencya-bucket"
  acl    = "private"
  tags = {
    Name = "myagencya-bucket1"
  }
}
