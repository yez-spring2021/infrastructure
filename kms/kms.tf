terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.30"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "profile" {
  type = string
  default = "dev"
}

data "aws_iam_role" "AWSServiceRoleForAutoScaling" {
  name = "AWSServiceRoleForAutoScaling"
}


resource "aws_kms_key" "ebs_kms_key" {
  enable_key_rotation = true
  description         = "kms for ebs volumn"
  deletion_window_in_days = 7
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "kms-ebs-1",
    "Statement": [
        
        {
            "Sid": "Allow direct access to key metadata to the account",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
              "kms:*"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_kms_alias" "ebs_alias" {
    name          = "alias/ebs-key-alias"
  target_key_id = aws_kms_key.ebs_kms_key.key_id
}

resource "aws_ebs_default_kms_key" "ebs_kms_key_default" {
  key_arn = aws_kms_key.ebs_kms_key.arn
}

resource "aws_ebs_encryption_by_default" "ebs_enable_encrypt" {
  enabled = true
}


