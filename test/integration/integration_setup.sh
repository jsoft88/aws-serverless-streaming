#!/bin/bash

set -e

CONTAINER_NAME="localstack_container"

# remove any existing container
docker container stop $CONTAINER_NAME && docker container rm $CONTAINER_NAME

docker run -d -p 4566:4566 \
    --name $CONTAINER_NAME \
    --env SERVICES=kinesis,lambda,firehose,cloudformation,iam,ec2,s3,ssm,sts \
    localstack/localstack:latest

until curl -sS -v --insecure -H "Accept: application/json" -i http://127.0.0.1:4566/health?reload
do
    echo "Sleeping 5 seconds before checking localstack health..."
    sleep 5
done