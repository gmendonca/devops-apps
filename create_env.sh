#!/bin/bash

# Configurations
#######################################################
# Edit this part to match your needs
#
VPC="vpc-6a62da0f"
SUBNETS="subnet-4801cb2d"
KEY_PAIR="guzz-sa"
#
#
#######################################################

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

#######################################################
# Python Application
#######################################################

# Creating a load balancer with the created Security Group and provided Subnets
LOAD_BALANCER_PY=`aws elb create-load-balancer --load-balancer-name lb-py-app \
--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
--subnets $SUBNETS --security-groups $SECURITY \
| python -c "import json,sys;print json.load(sys.stdin)['DNSName']"`

# Configuring Health Check to match especifications
aws elb configure-health-check --load-balancer-name lb-py-app \
--health-check Target=HTTP:80/ping,Interval=10,UnhealthyThreshold=5,HealthyThreshold=3,Timeout=5

# Create Launch Congifuration with the Userdata for the Python application
aws autoscaling create-launch-configuration --launch-configuration-name lc-py-app \
--image-id ami-fb890097 --instance-type t2.micro --security-groups $SECURITY \
--key-name $KEY_PAIR --user-data file://userdata-py

# Create Auto Scale Group with size 2 maximum and default 1
aws autoscaling create-auto-scaling-group --auto-scaling-group-name asg-py-app \
--launch-configuration-name lc-py-app --availability-zones "sa-east-1a" \
--load-balancer-names "lb-py-app" --max-size 2 --min-size 1 --desired-capacity 1

# Create policy to add 1 instance if needed
SCALE_OUT_PY=`aws autoscaling put-scaling-policy --auto-scaling-group-name asg-py-app \
--policy-name ScaleOutPY --scaling-adjustment 1 --adjustment-type ChangeInCapacity \
| python -c "import json,sys;print json.load(sys.stdin)['PolicyARN']"`

# Create alarm to add 1 instance when CPU Utilization is greater or equal to 70% for 5 minutes
aws cloudwatch put-metric-alarm --alarm-name AddCapacityPY --metric-name CPUUtilization --namespace AWS/EC2 \
--statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=asg-py-app" --evaluation-periods 2 --alarm-actions $SCALE_OUT_PY

# Create policy to remove 1 instance if needed
SCALE_IN_PY=`aws autoscaling put-scaling-policy --auto-scaling-group-name asg-py-app \
--policy-name ScaleInPY --scaling-adjustment -1 --adjustment-type ChangeInCapacity \
| python -c "import json,sys;print json.load(sys.stdin)['PolicyARN']"`

# Create alarm to remove 1 instance when CPU Utilization is less or equal to 30% for 5 minutes
aws cloudwatch put-metric-alarm --alarm-name RemoveCapacityPY --metric-name CPUUtilization --namespace AWS/EC2 \
--statistic Average --period 300 --threshold 30 --comparison-operator LessThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=asg-py-app" --evaluation-periods 2 --alarm-actions $SCALE_IN_PY


#######################################################
# PHP Application
#######################################################

mv ./userdata-php-e ./userdata-php
sed -i -e "s/myapp/$LOAD_BALANCER_PY/" ./userdata-php

# Creating a load balancer with the created Security Group and provided Subnets
LOAD_BALANCER_PHP=`aws elb create-load-balancer --load-balancer-name lb-php-app \
--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
--subnets $SUBNETS --security-groups $SECURITY \
| python -c "import json,sys;print json.load(sys.stdin)['DNSName']"`

# Configuring Health Check to match especifications
aws elb configure-health-check --load-balancer-name lb-php-app \
--health-check Target=HTTP:80/ping,Interval=10,UnhealthyThreshold=5,HealthyThreshold=3,Timeout=5

# Create Launch Congifuration with the Userdata for the PHP application
aws autoscaling create-launch-configuration --launch-configuration-name lc-php-app \
--image-id ami-fb890097 --instance-type t2.micro --security-groups $SECURITY \
--key-name $KEY_PAIR --user-data file://userdata-php

# Create Auto Scale Group with size 2 maximum and default 1
aws autoscaling create-auto-scaling-group --auto-scaling-group-name asg-php-app \
--launch-configuration-name lc-php-app --availability-zones "sa-east-1a" \
--load-balancer-names "lb-php-app" --max-size 2 --min-size 1 --desired-capacity 1

# Create policy to add 1 instance if needed
SCALE_OUT_PHP=`aws autoscaling put-scaling-policy --auto-scaling-group-name asg-php-app \
--policy-name ScaleOutPHP --scaling-adjustment 1 --adjustment-type ChangeInCapacity \
| python -c "import json,sys;print json.load(sys.stdin)['PolicyARN']"`

# Create alarm to add 1 instance when CPU Utilization is greater or equal to 70% for 5 minutes
aws cloudwatch put-metric-alarm --alarm-name AddCapacityPHP --metric-name CPUUtilization --namespace AWS/EC2 \
--statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=asg-php-app" --evaluation-periods 2 --alarm-actions $SCALE_OUT_PHP

# Create policy to remove 1 instance if needed
SCALE_IN_PHP=`aws autoscaling put-scaling-policy --auto-scaling-group-name asg-php-app \
--policy-name ScaleInPHP --scaling-adjustment -1 --adjustment-type ChangeInCapacity \
| python -c "import json,sys;print json.load(sys.stdin)['PolicyARN']"`

# Create alarm to remove 1 instance when CPU Utilization is less or equal to 30% for 5 minutes
aws cloudwatch put-metric-alarm --alarm-name RemoveCapacityPHP --metric-name CPUUtilization --namespace AWS/EC2 \
--statistic Average --period 300 --threshold 30 --comparison-operator LessThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=asg-php-app" --evaluation-periods 2 --alarm-actions $SCALE_IN_PHP
