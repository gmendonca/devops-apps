# DevOps Application

Automation script for create a Load Balanced Auto Scaling environment for Dockerized PHP and Python webapps.

## Configurations

* Dependecies: [Python](https://www.python.org/)<br />

* First you need to configure the environment in order to run the scripts. You can check how to install Amazon AWS CLI [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html) and configure.<br />

* When configuring, it's necessary to create an user with permissions to create all the environment and </br?>
then provide its AWS Access Key and Secret Access, set the default region name and the output format to json:

```bash
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: sa-east-1
Default output format [None]: json
```

## Creating VPC, Subnet and IGW

1 - Create a VPC with a CDIR block, for example 10.0.0.0/24<br />
2 - Create a Subnet within this VPC, for example 10.0.0.0/24<br />
3 - Create an Internet Gateway and attach in your VPC<br />
4 - Modify the Route Table of you VPC and add a target for your IGW using Destination 0.0.0.0/0<br />

* Later you need to edit two informations on the [create_env.sh](https://github.com/gmendonca/devops-apps/blob/master/create_env.sh) script. In the header of the file like shown below,
change the VPC, Subnet(s) and a key-pair name to match your needs accordingly to the created ones.

```bash
#######################################################
# Edit this part to match your needs
#
VPC="vpc-6example"
SUBNETS="subnet-4example"
KEY_PAIR="my-key-pair"
#
#
#######################################################
```

## Running

With all the configuration done, just run the script and wait for the environment finish setting up.

```bash
$ chmod +x create_env.sh
$ ./create_env.sh
```

There is a script to delete the environment, however it doesn't delete the VPC, Subnet and neither the Security Group.
```bash
$ chmod +x delete_env.sh
$ ./delete_env.sh
```
