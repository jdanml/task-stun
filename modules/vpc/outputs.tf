output "aws_vpc_id" {
  value = aws_vpc.env-vpc.id
}

output "aws_subnet_ids_public" {
  value = aws_subnet.env-vpc-subnets-public.*.id
}

output "aws_security_group" {
  value = aws_security_group.env.*.id
}

output "default_tags" {
  value = var.default_tags
}
