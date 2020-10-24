resource "aws_vpc" "env-vpc" {
  cidr_block = var.aws_vpc_cidr_block

  #DNS Related Entries
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-vpc"
  ))
}

resource "aws_internet_gateway" "env-vpc-internetgw" {
  vpc_id = aws_vpc.env-vpc.id

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-internetgw"
  ))
}

resource "aws_subnet" "env-vpc-subnets-public" {
  vpc_id            = aws_vpc.env-vpc.id
  count             = 1
#  count             = length(var.aws_avail_zones)
  availability_zone = element(var.aws_avail_zones, count.index)
  cidr_block        = var.aws_cidr_subnets_public

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-${element(var.aws_avail_zones, count.index)}-public"
  ))
}

resource "aws_route_table" "env-public" {
  vpc_id = aws_vpc.env-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.env-vpc-internetgw.id
  }

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-routetable-public"
  ))
}

resource "aws_route_table_association" "env-public" {
  count          = length(var.aws_cidr_subnets_public)
  subnet_id      = element(aws_subnet.env-vpc-subnets-public.*.id, count.index)
  route_table_id = aws_route_table.env-public.id
}

resource "aws_security_group" "env" {
  name   = "env-${var.aws_env_name}-securitygroup"
  vpc_id = aws_vpc.env-vpc.id

  tags = merge(var.default_tags, map(
    "Name", "env-${var.aws_env_name}-securitygroup"
  ))
}

resource "aws_security_group_rule" "allow-all-ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
#  cidr_blocks       = [var.aws_vpc_cidr_block]
  security_group_id = aws_security_group.env.id
}

resource "aws_security_group_rule" "allow-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.env.id
}

resource "aws_security_group_rule" "allow-ssh-connections" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.env.id
}
