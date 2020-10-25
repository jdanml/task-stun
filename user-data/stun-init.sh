#!/bin/bash
sudo apt-get update && sudo apt-get install collectd -y
cd /home/ubuntu/
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOL
{
    "agent": {
      "metrics_collection_interval": 60, 
      "logfile": "/var/log/amazon-cloudwatch-agent.log",
      "debug": false 
    },
    "logs": {
      "logs_collected": {
        "files": {
          "collect_list": [
            {
              "file_path": "/var/log/turnserver*.log", 
              "log_group_name": "stun-server-logs", 
              "log_stream_name": "{instance_id}" 
            }
          ]
        }
      }
    },
    "metrics": {
        "metrics_collected": {
            "collectd": { 
              "metrics_aggregation_interval": 60
            },
        "statsd": { 
          "metrics_aggregation_interval": 60,
          "metrics_collection_interval": 10,
          "service_address": ":8125"
        },
        "cpu": {
          "measurement": [
            "cpu_usage_idle",
            "cpu_usage_iowait",
            "cpu_usage_user",
            "cpu_usage_system"
          ],
          "totalcpu": true 
        },
        "disk": {
          "measurement": [
            "used_percent",
            "inodes_free"
          ],
          "resources": [
            "*"
          ]
        },
        "diskio": {
          "measurement": [
            "io_time",
            "write_bytes",
            "read_bytes",
            "writes",
            "reads"
          ],
          "resources": [
            "*"
          ]
        },
        "mem": {
          "measurement": [
            "mem_used_percent"
          ]
        },
        "netstat": {
          "measurement": [
            "tcp_established",
            "tcp_time_wait"
          ]
        },
        "swap": {
          "measurement": [
            "swap_used_percent"
          ]
        }
      }
    }
  }
EOL
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
sudo systemctl enable amazon-cloudwatch-agent 
sudo systemctl restart amazon-cloudwatch-agent 

privateIp="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
publicIp="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
sudo apt-get install -y dnsutils 
sudo apt-get install -y coturn
cat > /etc/turnserver.conf << EOL
realm=realmtest.com
fingerprint
external-ip=$publicIp
relay-ip=$privateIp
listening-port=3478
tls-listening-port=5349
min-port=10000
max-port=20000
log-file=/var/log/turnserver.log
verbose
lt-cred-mech
user=task:pass123
EOL
turnserver -c /etc/turnserver.conf -o