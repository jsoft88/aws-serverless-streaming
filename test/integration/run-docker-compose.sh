#!/bin/bash

env_type=$1
. "../../config_${env_type}.sh"

touch env.integration

echo "$fetcher_env_db_username=$db_master_username" > env.integration
echo "$fetcher_env_db_password=123456" >> env.integration
echo "$fetcher_env_db_host=127.0.0.1" >> env.integration
echo "$fetcher_env_db_port=33060" >> env.integration
echo "$fetcher_env_kinesis_stream_name=$delivery_stream_name" >> env.integration
echo "$fetcher_env_capture_from_schema=test_db" >> env.integration
echo "$fetcher_env_capture_from_table=test_table" >> env.integration
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> env.integration
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> env.integration
echo "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> env.integration

docker build -t mysql_mock:latest -f Dockerfile .

docker-compose -f mysql_python_docker_compose.yaml --env-file .env.integration up