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

data "aws_subnet_ids" "ec2_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
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

data "aws_security_group" "loadbalancer_security_group" {
  name = "loadbalancer_security_group"
  vpc_id = data.aws_vpc.vpc.id
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

data "aws_route53_zone" "webapp_route53_hosted_zone" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.webapp_route53_hosted_zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.webapp-load-balancer.dns_name
    zone_id                = aws_lb.webapp-load-balancer.zone_id
    evaluate_target_health = true
  }
}

# load balancer
resource "aws_lb" "webapp-load-balancer" {
  name               = "webapp-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.loadbalancer_security_group.id]
  subnets            = data.aws_subnet_ids.ec2_subnet_ids.ids

  enable_deletion_protection = false

  tags = {
    Name = "application-csye6225"
  }
}

# load balancer target group
# target for traffic forwarding
resource "aws_lb_target_group" "webapp-target-group" {
  name = "webapp-target-group"
  port = 8080
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc.id
  health_check {
    port = 8080
    matcher = 200
    path = "/books"
  }
}

//Load Balancer Listener
// forward traffic 80 to 8080
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.webapp-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-target-group.arn
  }
}


# auto scaling group configuration
resource "aws_launch_configuration" "asg_launch_config" {
  name  = "asg_launch_config"
  image_id      = data.aws_ami.ami.id
  instance_type = "t2.small"
  key_name = var.cred_vars["key_name"]
  security_groups = [data.aws_security_group.webapp_security_group.id]
  associate_public_ip_address = true
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
sudo echo "export SNS_TOPIC=${aws_sns_topic.webapp_sns_topic.arn}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export REALM=${var.realm}" >> /opt/tomcat/latest/bin/setenv.sh
sudo echo "export DOMAIN_NAME=${var.domain_name}" >> /opt/tomcat/latest/bin/setenv.sh
sudo chmod +x /opt/tomcat/latest/bin/setenv.sh
sudo systemctl start tomcat
   EOF


  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size =  20
    delete_on_termination = true
   }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  min_size             = 3
  max_size             = 5
  desired_capacity     = 3
  default_cooldown     = 60
  target_group_arns = [aws_lb_target_group.webapp-target-group.arn]
  vpc_zone_identifier  = data.aws_subnet_ids.ec2_subnet_ids.ids

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "application-csye6225"
    propagate_at_launch = true
  }
}

# autoscaling policy
# Scale Up Policy
resource "aws_autoscaling_policy" "WebServerScaleUpPolicy" {
  name                   = "WebServerScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

# Scale Down Policy
resource "aws_autoscaling_policy" "WebServerScaleDownPolicy" {
  name                   = "WebServerScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

# Alarm for CPU High
resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = "CPUAlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description = "Scale up if CPU > 5% for 300 seconds"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
 
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleUpPolicy.arn]
}

//Alarm for CPU Low
resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name          = "CPUAlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "3"
  alarm_description = "Scale down if CPU < 3% for 300 seconds"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
 
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleDownPolicy.arn]
}


// retrieve IAM role for codedeploy
data "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"
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
  service_role_arn      = data.aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  autoscaling_groups = [aws_autoscaling_group.asg.name]
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.webapp-target-group.name
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
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