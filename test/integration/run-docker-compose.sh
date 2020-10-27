#!/bin/bash

env_type=$1
. "../../config_${env_type}.sh"

docker-compose -f mysql_python_docker_compose.yaml up