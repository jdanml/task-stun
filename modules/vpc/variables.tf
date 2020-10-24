variable "aws_vpc_cidr_block" {
  description = "CIDR Blocks for AWS VPC"
}

variable "aws_env_name" {
  description = "Name of AWS Environment"
}

variable "aws_avail_zones" {
  description = "AWS Availability Zones Used"
  type        = list(string)
}

variable "aws_cidr_subnets_public" {
  description = "CIDR Blocks for public subnets in Availability zones"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
}
