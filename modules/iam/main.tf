#Add AWS Roles for env

resource "aws_iam_role" "stun-server" {
  name = "env-${var.aws_env_name}-stun"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
      }
  ]
}
EOF
}

resource "aws_iam_role_policy" "stun-server" {
  name = "env-${var.aws_env_name}-stun"
  role = aws_iam_role.stun-server.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["route53:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::env-*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "stun-server" {
  name = "kube_${var.aws_env_name}_stun_profile"
  role = aws_iam_role.stun-server.name
}