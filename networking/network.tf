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

variable "vpc_name" {
  type = string
  default = "csye6225"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

//vpc
// Create Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block                          = "10.0.0.0/16"
  enable_dns_hostnames                = true
  tags = {
    Name = var.vpc_name
    TWS = terraform.workspace
  }
}
// subnet
// Create subnets (Links to an external site.) in your VPC. You must create 3 subnets, each in different availability zone in the same region in the same VPC.
resource "aws_subnet" "main_subnet_01" {
  vpc_id                              = aws_vpc.main.id
  cidr_block                          = "10.0.1.0/24"
  availability_zone                   = format("%s%s", var.region, "a")
  map_public_ip_on_launch             =   true
  tags = {
    Name = format("%s-%s", var.vpc_name, "main_subnet_01")
  }
}

resource "aws_subnet" "main_subnet_02" {
  vpc_id                              = aws_vpc.main.id
  cidr_block                          = "10.0.2.0/24"
  availability_zone                   = format("%s%s", var.region, "b")
  map_public_ip_on_launch             =   true
  tags = {
    Name = format("%s-%s", var.vpc_name, "main_subnet_02")
  }
}

resource "aws_subnet" "main_subnet_03" {
  vpc_id                              = aws_vpc.main.id
  cidr_block                          = "10.0.3.0/24"
  availability_zone                   = format("%s%s", var.region, "c")
  map_public_ip_on_launch             =   true
  tags = {
    Name = format("%s-%s", var.vpc_name, "main_subnet_03")
  }
}

// internet gateway
// Create Internet Gateway (Links to an external site.) resource and attach the Internet Gateway to the VPC.
resource "aws_internet_gateway" "igw" {
  vpc_id                              = aws_vpc.main.id
  tags   = {
    Name = format("%s-%s", var.vpc_name, "igw")
  }
}

// route table
resource "aws_route_table" "rt" {
  vpc_id                              = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags   = {
    Name = format("%s-%s", var.vpc_name, "rt")
    TWS = terraform.workspace
  }
}
 // Create a public route table (Links to an external site.). Attach all subnets created above to the route table.
resource "aws_route_table_association" "asc1" {
  subnet_id = aws_subnet.main_subnet_01.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "asc2" {
  subnet_id = aws_subnet.main_subnet_02.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "asc3" {
  subnet_id = aws_subnet.main_subnet_03.id
  route_table_id = aws_route_table.rt.id
}

// Create a public route in the public route table created above with destination CIDR block 0.0.0.0/0 and internet gateway created above as the target.
resource "aws_route" "route" {
    route_table_id = aws_route_table.rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}
