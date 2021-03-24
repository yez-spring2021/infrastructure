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

# CodeDeploy-EC2-S3 IAM Policy
resource "aws_iam_policy" "CodeDeploy_ec2_s3_policy" {
  name        = "CodeDeploy-EC2-S3"
  path        = "/"
  description = "CodeDeploy S3 policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:GetObject",
                "s3:List*",
                "s3:Put*",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": [
              "arn:aws:s3:::${var.codedeploy_bucketname}",
              "arn:aws:s3:::${var.codedeploy_bucketname}/*"
              ]
        }
    ]
}
EOF
}

# GH-Upload-To-S3 IAM Policy
resource "aws_iam_policy" "GH-Upload-To-S3" {
  name        = "GH-Upload-To-S3"
  path        = "/"
  description = "GH-Upload-To-S3 policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:Put*",
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
              "arn:aws:s3:::${var.codedeploy_bucketname}",
              "arn:aws:s3:::${var.codedeploy_bucketname}/*"
            ]
        }
    ]
}
EOF
}

data "aws_caller_identity" "current_user_details" {}


# GH-Code-Deploy Policy
resource "aws_iam_policy" "GH-Code-Deploy" {
  name        = "GH-Code-Deploy"
  description = "GH-Code-Deploy policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current_user_details.account_id}:application:${var.codedeploy_application_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentgroup:${var.codedeploy_application_name}/${var.codedeploy_group_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
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

//codedeploy_ec2_service_role definition
resource "aws_iam_role" "CodeDeployEC2ServiceRole" {
  name = "CodeDeployEC2ServiceRole"

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

//CodeDeployServiceRole for the codedeploy service
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// resource "aws_iam_policy_attachment" "attachement" {
//   name       = "S3 Policy Attachment"
//   roles      = [aws_iam_role.ec2_role.name]
//   policy_arn = aws_iam_policy.s3_policy.arn
// }

// resource "aws_iam_policy_attachment" "codedeploy_s3_policy_attachment" {
//   name       = "CodeDeploy S3 Policy Attachment"
//   roles      = [aws_iam_role.ec2_role.name]
//   policy_arn = aws_iam_policy.CodeDeploy_ec2_s3_policy.arn
// }

//webapp s3 policy attachment
resource "aws_iam_policy_attachment" "attachement" {
  name       = "S3 Policy Attachment"
  roles      = [aws_iam_role.CodeDeployEC2ServiceRole.name]
  policy_arn = aws_iam_policy.s3_policy.arn
}

//CodeDeploy-EC2-S3 IAM Policy attachment to CodeDeployEC2ServiceRole role
resource "aws_iam_policy_attachment" "codedeploy_ec2_s3_policy_attachment" {
  name       = "CodeDeploy S3 Policy Attachment"
  roles      = [aws_iam_role.CodeDeployEC2ServiceRole.name]
  policy_arn = aws_iam_policy.CodeDeploy_ec2_s3_policy.arn
}

//adding policy of default policy AWSCodeDeployRole to CodeDeployServiceRole
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.CodeDeployServiceRole.name
}

data "aws_iam_user" "ghactions_user" {
  user_name = "ghactions"
}

//attachment of GH-Upload-To-S3 IAM Policy to ghactions_user
resource "aws_iam_user_policy_attachment" "ghactions_attach_gh_upload_to_s3_policy" {
  user       = data.aws_iam_user.ghactions_user.user_name
  policy_arn = aws_iam_policy.GH-Upload-To-S3.arn
}

//attachment of GH-Code-Deploy IAM Policy to ghactions_user
resource "aws_iam_user_policy_attachment" "ghactions_attach_ghcodedeploy_policy" {
  user       = data.aws_iam_user.ghactions_user.user_name
  policy_arn = aws_iam_policy.GH-Code-Deploy.arn
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.ec2_profile_name
  role = aws_iam_role.CodeDeployEC2ServiceRole.name
}


//codedeploy app
resource "aws_codedeploy_app" "csye6225-webapp" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}

//codedeploy group
resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name              = aws_codedeploy_app.csye6225-webapp.name
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn      = aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "application-csye6225"
    }
  }
}

# attach cloudwatch policy
resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.CodeDeployEC2ServiceRole.name
}