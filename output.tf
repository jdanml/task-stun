output "stun_ip" {
  value = join("\n", aws_instance.stun-server.*.public_ip)
}

output "default_tags" {
  value = var.default_tags
}
