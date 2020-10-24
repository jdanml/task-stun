resource "aws_iam_role" "stun-server-role" {
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

resource "aws_iam_role_policy" "stun-serve-policyr" {
  name = "env-${var.aws_env_name}-stun"
  role = aws_iam_role.stun-server-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "eu-west-3"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "stun-server-profile" {
  name = "kube_${var.aws_env_name}_stun_profile"
  role = aws_iam_role.stun-server-role.name
}