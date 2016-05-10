#!/bin/bash

echo "Deleting Auto Scaling Group for PHP App..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name asg-php-app --max-size 0 --min-size 0
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name asg-php-app --force-delete

echo "Deleting Auto Scaling Group for Python App..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name asg-py-app --max-size 0 --min-size 0
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name asg-py-app --force-delete

echo "Deleting Launch Configuration for PHP App..."
aws autoscaling delete-launch-configuration --launch-configuration-name lc-php-app

echo "Deleting Launch Configuration for Python App..."
aws autoscaling delete-launch-configuration --launch-configuration-name lc-py-app

echo "Deleting Load Balancer for PHP App..."
aws elb delete-load-balancer --load-balancer-name lb-php-app

echo "Deleting Load Balancer for Python App..."
aws elb delete-load-balancer --load-balancer-name lb-py-app
