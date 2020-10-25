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
  name = "${var.aws_env_name}-asg"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 2
  
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

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-stun-${count.index}",
    "Environment", "${var.aws_env_name}",
    "Role", "stun-${var.aws_env_name}-${count.index}"
  ))

}