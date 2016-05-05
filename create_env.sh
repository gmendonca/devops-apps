#!/bin/bash

# Configurations

VPC=vpc-6a62da0f
SUBNETS="subnet-4801cb2d subnet-57f0ac11"

# Creating security Group in the specified VPC
aws ec2 create-security-group --group-name php-py-app-sg \
--description "Security Group for PHP and Python applications" --vpc-id $VPC

# Getting the secuirty GroupId for further use
SECURITY=`aws ec2 describe-security-groups --group-names "php-py-app-sg" \
| python -c "import json,sys;print json.load(sys.stdin)['SecurityGroups'][0]['GroupId']"`

# Authorizing HTTP and SSH for the created Security Group
aws ec2 authorize-security-group-ingress --group-name php-py-app-sg \
--protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name php-py-app-sg \
--protocol tcp --port 80 --cidr 0.0.0.0/0

# Creating a load balancer with the created Security Group and provided Subnets
aws elb create-load-balancer --load-balancer-name lb-py-app \
--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
--subnets $SUBNETS --security-groups $SECURITY \
| python -c "import json,sys;print json.load(sys.stdin)['DNSName']"

# Configuring Health Check to match especifications
aws elb configure-health-check --load-balancer-name lb-py-app \
--health-check Target=HTTP:80/ping,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

aws autoscaling create-launch-configuration --launch-configuration-name lc-py-app \
--image-id ami-fb890097 --instance-type t2.micro --security-groups $SECURITY \
--user-data file://userdata-py

aws autoscaling create-auto-scaling-group --auto-scaling-group-name asg-py-app \
--launch-configuration-name lc-py-app --availability-zones "sa-east-1a" "sa-east-1c" \
--load-balancer-names "lb-py-app" --max-size 2 --min-size 1 --desired-capacity 1
