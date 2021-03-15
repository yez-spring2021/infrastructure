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

data "aws_iam_instance_profile" "ec2_profile" {
  name = var.ec2_profile_name
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
sudo systemctl stop tomcat
echo "#!/bin/sh" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export MYSQL_USERNAME=${var.cred_vars["username"]}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export MYSQL_PASSWORD=${var.cred_vars["password"]}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export MYSQL_HOSTNAME=${data.aws_db_instance.csye6225_rds.address}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export S3_BUCKET_NAME=${data.aws_s3_bucket.s3_bucket.bucket}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export MYSQL_ENDPOINT=${data.aws_db_instance.csye6225_rds.endpoint}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export RDS_DB_NAME=${data.aws_db_instance.csye6225_rds.db_name}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export EC2_PROFILE_NAME=${data.aws_iam_instance_profile.ec2_profile.name}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export REALM=${var.realm}" >> /opt/tomcat/latest/bin/setenv.sh
sudo chmod +x /opt/tomcat/latest/bin/setenv.sh
sudo systemctl start tomcat
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
