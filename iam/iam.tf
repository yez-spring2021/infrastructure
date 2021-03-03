terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.30"
    }
  }
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "profile" {
  type = string
  default = "dev"
}

variable "s3_policy" {
  type = string
  default = "WebAppS3"
}

variable "bucket_name" {
  type = string
  default = "webapp.zhenyu.ye"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}
// s3 policy
resource "aws_iam_policy" "s3_policy" {
  name = var.s3_policy
  path = "/"
  description = "WebAppS3 policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.bucket_name}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::${var.bucket_name}/*"]
        }
    ]
}
EOF
}


//EC2 IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"
  path = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "attachement" {
  name       = "S3 Policy Attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.s3_policy.arn
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "csye6225_profile"
  role = aws_iam_role.ec2_role.name
}
