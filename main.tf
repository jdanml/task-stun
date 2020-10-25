terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  region     = var.aws_region
}

data "aws_availability_zones" "azs" {}

module "aws-vpc" {
  source = "./modules/vpc"

  aws_env_name             = var.aws_env_name
  aws_vpc_cidr_block       = var.aws_vpc_cidr_block
  aws_avail_zones          = slice(data.aws_availability_zones.azs.names, 0, 2)
  aws_cidr_subnets_public  = var.aws_cidr_subnets_public
  default_tags             = var.default_tags
}

module "aws-iam" {
  source = "./modules/iam"
  aws_env_name= var.aws_env_name
}

module "monitoring" {
  source = "./modules/cloudwatch"
  dashboard_name = var.dashboard_name
}


module "ec2-keypair" {
  source = "./modules/ec2-keypair"

  aws_env_name                = var.aws_env_name
  public_key_file             = "key/stun-${var.aws_env_name}.id_rsa.pub"
  private_key_file            = "key/stun-${var.aws_env_name}.id_rsa"
  key_name                    = "stun-${var.aws_env_name}"
}

resource "aws_launch_configuration" "stun-server" {
  image_id                    = data.aws_ami.distro.id
  instance_type               = var.aws_stun_size
  associate_public_ip_address = true

  security_groups = module.aws-vpc.aws_security_group

  key_name = module.ec2-keypair.key_name
  iam_instance_profile = module.aws-iam.stun-server-profile
  user_data = file("user-data/stun-init.sh")

}

resource "aws_autoscaling_group" "stun-asg" {
  name = "env-${var.aws_env_name}-stun"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 4

  health_check_type    = "EC2"
  
  launch_configuration = aws_launch_configuration.stun-server.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier  = module.aws-vpc.aws_subnet_ids_public

  lifecycle {
    create_before_destroy = true
  }

    tag {
    key                 = "Name"
    value               = "env-${var.aws_env_name}-stun"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "stun_policy_up" {
  name = "stun_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 200
  autoscaling_group_name = aws_autoscaling_group.stun-asg.name
}

resource "aws_cloudwatch_metric_alarm" "stun_cpu_alarm_up" {
  alarm_name = "stun_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.stun-asg.name
  }

  alarm_description = "This metric monitors EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.stun_policy_up.arn ]
}

resource "aws_autoscaling_policy" "stun_policy_down" {
  name = "stun_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 200
  autoscaling_group_name = aws_autoscaling_group.stun-asg.name
}

resource "aws_cloudwatch_metric_alarm" "stun_cpu_alarm_down" {
  alarm_name = "stun_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.stun-asg.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.stun_policy_down.arn  ]
}