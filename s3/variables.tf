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

variable "serverless_bucketname" {
  type = string
  default = "serverless.dev.zhenyuye.me"
}
