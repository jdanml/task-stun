output "stun-server-profile" {
  value = aws_iam_instance_profile.stun-server.name
}

output "kube-worker-profile" {
  value = aws_iam_instance_profile.kube-worker.name
}
