variable "aws_region" {
  description = "AWS Region"
  default     = "eu-west-3"
}

variable "aws_env_name" {
  description = "Name of AWS Environment"
}

variable "aws_vpc_cidr_block" {
  description = "CIDR Block for VPC"
}

variable "aws_cidr_subnets_public" {
  description = "CIDR Blocks for public subnets in Availability Zones"
  type        = list(string)
}

data "aws_ami" "distro" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
}

variable "aws_stun_size" {
  description = "EC2 Instance Size of Stun servers"
}

variable "aws_stun_server_num" {
  description = "Number of Stun servers"
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
}