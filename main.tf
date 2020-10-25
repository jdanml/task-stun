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

  dashboard_name           = var.dashboard_name
}


module "ec2-keypair" {
  source = "./modules/ec2-keypair"

  aws_env_name                = var.aws_env_name
  public_key_file             = "key/stun-${var.aws_env_name}.id_rsa.pub"
  private_key_file            = "key/stun-${var.aws_env_name}.id_rsa"
  key_name                    = "stun-${var.aws_env_name}"
}

resource "aws_instance" "stun-server" {
  ami                         = data.aws_ami.distro.id
  instance_type               = var.aws_stun_size
  count                       = var.aws_stun_server_num
  associate_public_ip_address = true
  availability_zone           = element(slice(data.aws_availability_zones.azs.names, 0, 2), count.index)
  subnet_id                   = element(module.aws-vpc.aws_subnet_ids_public, count.index)

  vpc_security_group_ids = module.aws-vpc.aws_security_group

  key_name = module.ec2-keypair.key_name
  iam_instance_profile = module.aws-iam.stun-server-profile
  user_data = file("user-data/stun-init.sh")

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-stun-${count.index}",
    "Environment", "${var.aws_env_name}",
    "Role", "stun-${var.aws_env_name}-${count.index}"
  ))
}