# DevOps Application

Automation script for create a Load Balanced Auto Scaling environment for Dockerized PHP and Python webapps.

## Configurations

Dependecies: [Python](https://www.python.org/)<br />

* First you need to configure the environment in order to run the scripts. You can check how to install Amazon AWS CLI [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html) and configure.<br />

* When configuring:

```bash
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: sa-east-1
Default output format [None]: json
```

* Later you need to edit two informations on the [create_env.sh]() script. In the header of the file like shown below,
change the VPC, Subnet(s) and a key-pair name to match your needs.

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

* With all the configuration done, just run the script and wait for the environment finish setting up.

```bash
$ chmod +x create_env.sh
$ ./create_env.sh
```
