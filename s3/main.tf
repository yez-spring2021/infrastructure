terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
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

variable "bucket_name" {
  type = string
  default = "webapp.zhenyu.ye"
}

variable "iam_user" {
  type = string
  default = "dev"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

// S3 bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  acl    = "private"
  force_destroy = true
  versioning {
      enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  lifecycle_rule {
    enabled = true
    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
  }
}

data "aws_iam_user" "selected" {
  user_name = var.iam_user
}

// // IAM Policy for S3 bucket
// resource "aws_s3_bucket_policy" "bucket_policy" {
//   bucket = aws_s3_bucket.s3_bucket.id
//   policy = <<POLICY
// {
//     "Version": "2012-10-17",
//     "Id": "Policy1488494182833",
//     "Statement": [
//         {
//             "Sid": "Stmt1488493308547",
//             "Effect": "Allow",
//             "Principal": {
//                 "AWS": "${data.aws_iam_user.selected.arn}"
//             },
//             "Action": [
//                 "s3:ListBucket",
//                 "s3:ListBucketVersions",
//                 "s3:GetBucketLocation",
//                 "s3:Get*",
//                 "s3:Put*",
//                 "s3:Delete*"
//             ],
//             "Resource": "arn:aws:s3:::${var.bucket_name}"
//         }
//     ]
// }
// POLICY
// }
