#!/bin/bash

export PYTHON_APP_ADDRESS="http://54.213.17.7/"

source /etc/apache2/envvars
tail -F /var/log/apache2/* &
exec apache2 -D FOREGROUND
