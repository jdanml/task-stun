resource "aws_cloudwatch_dashboard" "stun-server-dashboard" {
    dashboard_name = var.dashboard_name
    dashboard_body = <<EOF
    {
    "widgets": [
        {
            "type": "log",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE 'stun-server-logs' | fields @timestamp, @message\n| filter @message like /closed/ \n| stats count(*) as closedsessionCount by bin(1h)\n| sort exceptionCount desc",
                "region": "eu-west-3",
                "stacked": true,
                "title": "Log group: stun-server-logs",
                "view": "timeSeries"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE 'stun-server-logs' | fields @timestamp, @message\n| filter @message like /incoming packet BINDING processed, success/ \n| stats count(*) as bindingsuccessCount by bin(1h)\n| sort exceptionCount desc",
                "region": "eu-west-3",
                "stacked": true,
                "view": "timeSeries"
            }
        }
    ]
}
EOF
}