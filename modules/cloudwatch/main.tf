resource "aws_cloudwatch_dashboard" "stun-server-dashboard" {
    dashboard_name = var.dashboard_name
    dashboard_body = <<EOF
    {
    "widgets": [
        {
            "type": "log",
            "x": 0,
            "y": 3,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE 'stun-server-logs' | fields @timestamp, @message\n| filter @message like /closed/ \n| stats count(*) as closedsessionCount by bin(60s)",
                "region": "eu-west-3",
                "stacked": false,
                "title": "Closed Session Count",
                "view": "bar"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 9,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE 'stun-server-logs' | fields @timestamp, @message\n| filter @message like /incoming packet BINDING processed, success/ \n| stats count(*) as bindingsuccessCount by bin(60s)",
                "region": "eu-west-3",
                "stacked": false,
                "title": "Binding Success Count",
                "view": "bar"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 3,
            "properties": {
                "view": "singleValue",
                "metrics": [
                    [ "AWS/AutoScaling", "GroupMaxSize", "AutoScalingGroupName", "env-task-stun" ],
                    [ ".", "GroupDesiredCapacity", ".", "." ],
                    [ ".", "GroupMinSize", ".", "." ],
                    [ ".", "GroupTotalInstances", ".", "." ],
                    [ ".", "GroupInServiceInstances", ".", "." ]
                ],
                "region": "eu-west-3"
            }
        }
    ]
}
EOF
}