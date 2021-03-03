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

data "aws_security_group" "db_security_group" {
  name = "database"
}

data "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = data.aws_subnet_ids.subnet_ids.ids

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_db_parameter_group" "db_params_group" {
  name   = "rds-pg"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
    apply_method = "pending-reboot"
  }
}

data "aws_rds_certificate" "rdscert" {
  latest_valid_till = true
}


resource "aws_db_instance" "csye6225_rds" {
  allocated_storage = 10
  storage_type = "gp2"
  engine = "mysql"
  instance_class = "db.t3.micro"
  name = var.cred_vars["name"]
  username = var.cred_vars["username"]
  password = var.cred_vars["password"]
  multi_az = false
  publicly_accessible = false
  identifier = var.cred_vars["identifier"]
  skip_final_snapshot = true
  vpc_security_group_ids = [data.aws_security_group.db_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  storage_encrypted = true
  parameter_group_name = aws_db_parameter_group.db_params_group.name
  ca_cert_identifier = data.aws_rds_certificate.rdscert.id
}

resource "aws_db_instance" "test" {
  allocated_storage = 10
  storage_type = "gp2"
  engine = "mysql"
  instance_class = "db.t3.micro"
  name = var.cred_vars["name"]
  username = var.cred_vars["username"]
  password = var.cred_vars["password"]
  multi_az = false
  publicly_accessible = true
  identifier = format("%s-%s",var.cred_vars["identifier"], "test") 
  skip_final_snapshot = true
  vpc_security_group_ids = [data.aws_security_group.db_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  storage_encrypted = true
  parameter_group_name = aws_db_parameter_group.db_params_group.name
  ca_cert_identifier = data.aws_rds_certificate.rdscert.id
}
