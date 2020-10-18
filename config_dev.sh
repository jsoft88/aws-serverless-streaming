#!/bin/bash

export AWS_PROFILE=""
export DEFAULT_AWS_REGION=""
# Prefix to use to name provisioned resources
export env=$1
# S3 bucket to store packaged Lambdas
export s3_bucket_deployment_artifacts="m3d.opensource.inbound"

# Stacks to create
export aurora_stack_name="aurora-${env}"
export network_stack_name="network-stack-${env}"
export ecs_stack_name="ecs-stack-${env}"
export kinesis_stream_stack_name="kinesis-stream-stack-${env}"
export kinesis_firehose_stack_name="kinesis-firehose-stack-${env}"
export lambda_stack_name="lambda-stack-${env}"

# ----- RDS Stack ----- #
# RDS database name (a-zA-Z0-9_)
export db_name="database-1"
# RDS Aurora Serverless Cluster Name (a-zA-Z0-9-)
export db_cluster_name="orders-db-${env}"
# RDS Master Username
export db_master_username="db_user" # password will be create on-the-fly and associtated w/ this user
export db_password_secret_ssm_key="password-secret-${env}"
export delivery_stream_name="kinesis-db-changes-stream-${env}"
export lambda_kinesis_stream_processor_bucket="lambdas-stream"
export lambda_kinesis_stream_processor_prefix="${env}/kinesis-stream-2-firehose"
export lambda_kinesis_stream_processor_version="latest"
export lambda_kinesis_stream_handler="org.jc.aws.lambda.DBChangeCapture.handleRequest"
export lambda_kinesis_stream_processor_runtime="java8"
export lambda_kinesis_stream_batching_seconds="0"
export lambda_kinesis_firehose_batch_seconds="10"
export lambda_kinesis_firehose_batch_mbs="4"
export lambda_kinesis_firehose_s3_bucket=m3d.opensource.landing
export lambda_kinesis_firehose_s3_destination_arn="arn:aws:s3:::$lambda_kinesis_firehose_s3_bucket/db_streams"
export lambda_kinesis_firehose_delivery_type="DirectPut"
export lambda_kinesis_firehose_stream_name="db-changes-fh-s3"
export fetcher_env_db_username="DB_USERNAME"
export fetcher_env_db_password="DB_PASSWORD"
export fetcher_env_db_host="DB_HOST"
export fetcher_env_db_port="DB_PORT"
export fetcher_env_kinesis_stream_name="KINESIS_STREAM_NAME"
export fetcher_env_capture_from_schema="CAPTURE_FROM_SCHEMA"
export fetcher_env_capture_from_table="CAPTURE_FROM_TABLE"
export fetcher_image_name="jsoft88/fetcher-aurora-${env}"
export fetcher_ecs_task_family="fetcher-${env}"
 
# ----- API Stack ----- #
export log_level="DEBUG"  # debug/info/error

# ---------------------------------------------------------------

# You probably don't need to change these values
export app_name="serverless-streaming-db-changes"
export rds_cfn_template="rds_cfn_template.yaml"
export api_cfn_template="api_cfn_template.yaml"
export gen_api_cfn_template="generated-${api_cfn_template}"
export sam_build_dir=".aws-sam"
export lambdas_dir="lambdas"