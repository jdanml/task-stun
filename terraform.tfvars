#Global Vars
aws_env_name= "task"

#VPC Vars
aws_vpc_cidr_block       = "10.200.0.0/16"
aws_cidr_subnets_public  = ["10.200.1.0/24", "10.200.2.0/24"]

#Monitoring
dashboard_name = "stun-dashboard"

#Stun Server
aws_stun_size = "t2.micro"

default_tags = {
  #  Env = "devtest"
  #  Product = "stun"
}