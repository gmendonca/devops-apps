#!/bin/bash

# Configurations
#######################################################
# Edit this part to match your needs
#
VPC="vpc-ca2c3caf"
SUBNETS="subnet-ecd07188"
KEY_PAIR="my-key-pair"
#
#
#######################################################

if [ -f $KEY_PAIR.pem ];
then
   echo "Key-pair $KEY_PAIR.pem already exists."
else
   echo "Creating $KEY_PAIR.pem..."
   aws ec2 create-key-pair --key-name $KEY_PAIR --query 'KeyMaterial' --output text > $KEY_PAIR.pem
fi


CHECK_SG=`aws ec2 describe-security-groups --filter Name=group-name,Values=php-py-app-sg Name=vpc-id,Values=$VPC --query "length(*[0])"`

if [[ $CHECK_SG -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Security Group..."
    aws ec2 create-security-group --group-name php-py-app-sg \
    --description "Security Group for PHP and Python applications" --vpc-id $VPC
else
    echo "Security Group already exists."
fi

# Getting the secuirty GroupId for further use
SECURITY=`aws ec2 describe-security-groups --filters Name=group-name,Values=php-py-app-sg Name=vpc-id,Values=$VPC \
| python -c "import json,sys;print json.load(sys.stdin)['SecurityGroups'][0]['GroupId']"`


# Authorizing HTTP and SSH for the created Security Group
SSH_SG=`aws ec2 describe-security-groups --filters Name=group-name,Values=php-py-app-sg Name=vpc-id,Values=$VPC \
Name=ip-permission.from-port,Values=22 Name=ip-permission.to-port,\
Values=22 Name=ip-permission.cidr,Values='0.0.0.0/0' --query 'length(*[0])'`

if [[ $SSH_SG -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Inbound rule for SSH..."
    aws ec2 authorize-security-group-ingress --group-id $SECURITY \
    --protocol tcp --port 22 --cidr 0.0.0.0/0
else
    echo "Inbound rule for SSH already exists."
fi

HTTP_SG=`aws ec2 describe-security-groups --filters Name=group-name,Values=php-py-app-sg Name=vpc-id,Values=$VPC \
Name=ip-permission.from-port,Values=80 Name=ip-permission.to-port,\
Values=80 Name=ip-permission.cidr,Values='0.0.0.0/0' --query 'length(*[0])'`

if [[ $HTTP_SG -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Inbound rule for HTTP..."
    aws ec2 authorize-security-group-ingress --group-id $SECURITY \
    --protocol tcp --port 80 --cidr 0.0.0.0/0
else
    echo "Inbound rule for HTTP already exists."
fi

#######################################################
# Python Application
#######################################################

# Creating a load balancer with the created Security Group and provided Subnets
LOAD_BALANCER_PY=`aws elb create-load-balancer --load-balancer-name lb-py-app \
--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
--subnets $SUBNETS --security-groups $SECURITY \
| python -c "import json,sys;print json.load(sys.stdin)['DNSName']"`

# Configuring Health Check to match especifications
echo "Configuring Health Check for Python App:"
aws elb configure-health-check --load-balancer-name lb-py-app \
--health-check Target=HTTP:80/ping,Interval=10,UnhealthyThreshold=5,HealthyThreshold=3,Timeout=5

# Create Launch Congifuration with the Userdata for the Python application
LC_PY=`aws autoscaling describe-launch-configurations --launch-configuration-names lc-py-app --query "length(*[0])"`
if [[ $LC_PY -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Launch Configuration Group for the Python App..."
    aws autoscaling create-launch-configuration --launch-configuration-name lc-py-app \
    --image-id ami-fb890097 --instance-type t2.micro --security-groups $SECURITY \
    --associate-public-ip-address --key-name $KEY_PAIR --user-data file://userdata-py
else
    echo "Launch Configuration for Python App already exists."
fi

# Create Auto Scale Group with size 2 maximum and default 1
ASG_PY=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name asg-py-app --query "length(*[0])"`
if [[ $ASG_PY -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Auto Scaling Group for the Python App..."
    aws autoscaling create-auto-scaling-group --auto-scaling-group-name asg-py-app \
    --launch-configuration-name lc-py-app --availability-zones "sa-east-1a" --vpc-zone-identifier $SUBNETS \
    --load-balancer-names "lb-py-app" --max-size 2 --min-size 1 --desired-capacity 1
else
    echo "Auto Scaling Group for Python App already exists."
fi


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

echo "Configuring userdata for PHP App to match the Load Balancer from Python App..."
if [ -f userdata-php-e ];
then
   mv ./userdata-php-e ./userdata-php
fi

sed -i -e "s/myapp/$LOAD_BALANCER_PY/" ./userdata-php
echo "Done."

# Creating a load balancer with the created Security Group and provided Subnets
LOAD_BALANCER_PHP=`aws elb create-load-balancer --load-balancer-name lb-php-app \
--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
--subnets $SUBNETS --security-groups $SECURITY \
| python -c "import json,sys;print json.load(sys.stdin)['DNSName']"`

# Configuring Health Check to match especifications
echo "Configuring Health Check for PHP App:"
aws elb configure-health-check --load-balancer-name lb-php-app \
--health-check Target=HTTP:80/ping,Interval=10,UnhealthyThreshold=5,HealthyThreshold=3,Timeout=5

# Create Launch Congifuration with the Userdata for the PHP application
LC_PHP=`aws autoscaling describe-launch-configurations --launch-configuration-names lc-php-app --query "length(*[0])"`
if [[ $LC_PHP -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Launch Configuration Group for the PHP App..."
    aws autoscaling create-launch-configuration --launch-configuration-name lc-php-app \
    --image-id ami-fb890097 --instance-type t2.micro --security-groups $SECURITY \
    --associate-public-ip-address --key-name $KEY_PAIR --user-data file://userdata-php
else
    echo "Launch Configuration for PHP App already exists."
fi


# Create Auto Scale Group with size 2 maximum and default 1
ASG_PHP=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name asg-php-app --query "length(*[0])"`
if [[ $ASG_PHP -eq 0 ]];
then
    # Creating security Group in the specified VPC
    echo "Creating Auto Scaling Group for the PHP App..."
    aws autoscaling create-auto-scaling-group --auto-scaling-group-name asg-php-app \
    --launch-configuration-name lc-php-app --availability-zones "sa-east-1a" --vpc-zone-identifier $SUBNETS\
    --load-balancer-names "lb-php-app" --max-size 2 --min-size 1 --desired-capacity 1
else
    echo "Auto Scaling Group for PHP App already exists."
fi


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

echo "Set up complete. Application will be available on http://$LOAD_BALANCER_PHP soon!"
