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

variable "bucket_name" {
  type = string
  default = "webapp.zhenyu.ye"
}

variable "realm" {
  type = string
  default = "dev"
}

variable "cred_vars" {
  type = map(string)

  default = {
    "username" = "csye6225"
    "password" = "Cloud456!"
    "name" = "csye6225"
    "identifier" = "csye6225"
    "key_name" = "csye6225"
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_subnet" "ec2_subnet" {
  vpc_id = data.aws_vpc.vpc.id
  availability_zone = "us-east-1a"
}

data "aws_ami" "ami" {
  executable_users = ["self"]
  most_recent      = true
  owners = ["236694925932"]
  filter {
    name = "name"
    values = ["csye*"]
  }
}

data "aws_security_group" "webapp_security_group" {
  name = "application"
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_db_instance" "csye6225_rds" {
  db_instance_identifier = var.cred_vars["identifier"]
}

data "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}

data "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"
}

data "aws_iam_instance_profile" "ec2_profile" {
  name = "csye6225_profile"
}

resource "aws_instance" "ec2_instance" {
  ami = data.aws_ami.ami.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.ec2_subnet.id
  key_name = var.cred_vars["key_name"]
  vpc_security_group_ids = [data.aws_security_group.webapp_security_group.id]
  disable_api_termination = false
  iam_instance_profile = data.aws_iam_instance_profile.ec2_profile.name
  user_data = <<EOF
#!/bin/bash
echo "User Data:"
sudo touch .env\n
sudo echo "MYSQL_USERNAME=${var.cred_vars["username"]}" >> /etc/environment
sudo echo "MYSQL_PASSWORD=${var.cred_vars["password"]}" >> /etc/environment
sudo echo "MYSQL_HOSTNAME=${data.aws_db_instance.csye6225_rds.address}" >> /etc/environment
sudo echo "S3_BUCKET_NAME=${data.aws_s3_bucket.s3_bucket.bucket}" >> /etc/environment
sudo echo "MYSQL_ENDPOINT=${data.aws_db_instance.csye6225_rds.endpoint}" >> /etc/environment
sudo echo "RDS_DB_NAME=${data.aws_db_instance.csye6225_rds.db_name}" >> /etc/environment
sudo echo "EC2_PROFILE_NAME=${data.aws_iam_instance_profile.ec2_profile.name}" >> /etc/environment
sudo echo "REALM=${var.realm}" >> /etc/environment
   EOF


   root_block_device {
       volume_type = "gp2"
       volume_size =  20
       delete_on_termination = true
   }
   tags = {
     Name = "application-csye6225"
   }
}
