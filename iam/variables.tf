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

variable "codedeploy_bucketname" {
  type = string
  default = "codedeploy.dev.webapp.zhenyu.ye"
}

variable "codedeploy_application_name"{
  default = "csye6225-webapp"
}

variable "codedeploy_group_name"{
  default = "csye6225-webapp-deployment"
}

variable "ec2_profile_name" {
  type = string
  default = "ec2_profile"
}