terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

}


# EC2 Security Groups
resource "aws_security_group" "allow_tls" {
  name        = "application"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_443]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_80]
  }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_22]
  }

  ingress {
    description = "PORT 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_8080]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

#Database Security Group
resource "aws_security_group" "database_security_group" {
  name = "database"
  vpc_id = data.aws_vpc.vpc.id
  description = "Allow database traffic"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    description = "PORT 3306"
    security_groups = [aws_security_group.allow_tls.id]
    // remove when before submit
    cidr_blocks = [var.cidr_block_3306]
  }

    tags = {
    Name = "database_security_group"
  }
}