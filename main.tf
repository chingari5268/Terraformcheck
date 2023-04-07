provider "aws" {
  region = "us-east-1" # replace with your desired region
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "mybucketterraformmmm" # replace with your desired bucket name
  acl    = "private"
  
  tags = {
    Environment = "dev"
  }
}
