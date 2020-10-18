#!/bin/bash

set -e

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_DEFAULT_REGION
unset AWS_PROFILE
unset SERVICES

docker-compose down && docker container stop localstack_container

