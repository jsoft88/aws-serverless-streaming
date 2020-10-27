#!/bin/bash

set -e

function error() {
    echo "Error: $1"
    exit -1
}
[[ -n "$1" ]] || error "Missing environment name (integration, eg, dev, qa, prod)"
[[ -n "$2" && "$1" = "integration" ]] || error "Missing deployment id: network-stack, kinesis-stream-stack, kinesis-firehose-stack, lambda-stack"
env_type=$1
deployment=$2
echo "WORKDIR IS: $(pwd)"

. "./config_${env_type}.sh"

if [ "$env_type" = "integration" ];
then
	export ENPOINT_URL_FLAG="--endpoint-url http://localhost:4566";
	aws s3api head-bucket --bucket $lambda_kinesis_stream_processor_bucket $ENPOINT_URL_FLAG || aws s3 mb $ENPOINT_URL_FLAG s3://$lambda_kinesis_stream_processor_bucket;
	aws s3api head-bucket --bucket $lambda_kinesis_firehose_s3_bucket $ENPOINT_URL_FLAG || aws s3 mb $ENPOINT_URL_FLAG s3://$lambda_kinesis_firehose_s3_bucket;

	# Build lambda processor JAR

	mvn clean package -DskipTests=true -DoutputDirectory=./lambda/target/ -f ./lambda/pom.xml
	# upload JAR to S3
	aws s3 cp ./lambda/target/serverlessDBStreaming-1.0-SNAPSHOT.jar "s3://$lambda_kinesis_stream_processor_bucket/$lambda_kinesis_stream_processor_prefix" $ENPOINT_URL_FLAG

	# register secret for db
	# aws ssm put-parameter --type SecureString --value 123456 --name $db_password_secret_ssm_key $ENDPOINT_URL
fi

if [ "$env_type" != "integration" -o "$deployment" = "network-stack" ]; then
	aws cloudformation create-stack \
	    --template-body "file://cfn/network_setup.yaml" \
	    --stack-name $network_stack_name \
		$ENPOINT_URL_FLAG

	sleep 180
fi

# Unfortunately localstack CE does not have RDS or ECS service included, so we have to find a workaround this.
if [ "$env_type" != "integration" ]; then
	aws $ENPOINT_URL_FLAG cloudformation create-stack \
	    --template-body "file://cfn/aurora-db-provisioning.yaml" \
	    --stack-name $rds_stack_name \
	    --parameters \
	        ParameterKey="AppName",ParameterValue="$app_name" \
	        ParameterKey="EnvType",ParameterValue="$env_type" \
	        ParameterKey="DBClusterName",ParameterValue="$db_cluster_name" \
	        ParameterKey="DatabaseName",ParameterValue="$db_name" \
	        ParameterKey="DBMasterUserName",ParameterValue="$db_master_username" \
	        ParameterKey="NetworkStackName",ParameterValue="$network_stack_name" \
	        ParameterKey="DBSecretSSMKey",ParameterValue="$db_password_secret_ssm_key"
	    --capabilities \
	        CAPABILITY_IAM

	# TODO: wait stack creation/update completion
	sleep 180

	# Enable the Data API
	aws rds modify-db-cluster --db-cluster-identifier $db_cluster_name --enable-http-endpoint

	aws rds create-db-cluster-parameter-group enable_binlog_group --db-parameter-group-family "Aurora MySQL" --description "Enable binlog"

	aws rds modify-db-parameter-group \
	    --db-parameter-group-name enable_binlog_group \
	    --parameters "ParameterName='binlog_format',ParameterValue=ROW,ApplyMethod=immediate"

	sleep 60

	docker build -t $fetcher_image_name:latest
	$(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
	docker tag $fetcher_image_name:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$fetcher_image_name:latest
	docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$fetcher_image_name:latest

	# Create ecs stack for python fetcher
	aws cloudformation create-stack \
	    --template-body "file://cfn/fargate_setup.yaml" \
	    --stack-name $ecs_stack_name \
	    --parameters \
	        ParameterKey="NetworkStackName",ParameterValue="$network_stack_name" \
	        ParameterKey="DBStackName",ParameterValue="$aurora_stack_name" \
	        ParameterKey="Image",ParameterValue="$fetcher_image_name" \
	        ParameterKey="ContainerCpu",ParameterValue="2048" \
	        ParameterKey="ContainerMemory",ParameterValue="4096" \
	        ParameterKey="Family",ParameterValue="$fetcher_ecs_task_family" \
	        ParameterKey="KinesisStreamName",ParameterValue="$delivery_stream_name" \
	        ParameterKey="DBUsername",ParameterValue="$db_master_username" \
	        ParameterKey="DBUsernameEnvName",ParameterValue="$fetcher_env_db_username" \
	        ParameterKey="DBPasswordEnvName",ParameterValue="$fetcher_env_db_password" \
	        ParameterKey="DBHostEnvName",ParameterValue="$fetcher_env_db_host" \
	        ParameterKey="DBPortEnvName",ParameterValue="$fetcher_env_db_port" \
	        ParameterKey="KinesisStreamEnvName",ParameterValue="$fetcher_env_kinesis_stream_name" \
	        ParameterKey="CaptureDBSchema",ParameterValue="$fetcher_env_capture_from_schema" \
	        ParameterKey="CaptureDBTable",ParameterValue="$fetcher_env_capture_from_table" \
	    --capabilities CAPABILITY_IAM

	sleep 180
fi

if [ "$env_type" != "integration" -o "$deployment" = "kinesis-stream-stack" ]; then
	# Create kinesis stream stack
	aws $ENPOINT_URL_FLAG cloudformation create-stack \
	    --template-body "file://cfn/kinesis_stream_setup.yaml" \
	    --stack-name $kinesis_stream_stack_name \
	    --parameters \
	        ParameterKey="KinesisStreamName",ParameterValue="$delivery_stream_name" \
	    --capabilities CAPABILITY_AUTO_EXPAND

	sleep 180
fi

if [ "$env_type" != "integration" -o "$deployment" = "kinesis-firehose-stack" ]; then
	# Create kinesis firehose stack
	aws $ENPOINT_URL_FLAG cloudformation create-stack \
	    --template-body "file://cfn/kinesis_firehose_setup.yaml" \
	    --stack-name $kinesis_firehose_stack_name \
	    --parameters \
	        ParameterKey="DeliveryStreamName",ParameterValue="$lambda_kinesis_firehose_stream_name" \
	        ParameterKey="DeliveryStreamType",ParameterValue="$lambda_kinesis_firehose_delivery_type" \
	        ParameterKey="BufferDurationSeconds",ParameterValue="$lambda_kinesis_firehose_batch_seconds" \
	        ParameterKey="BufferSizeMBs",ParameterValue="$lambda_kinesis_firehose_batch_mbs" \
	        ParameterKey="FirehoseS3DestinationArn",ParameterValue="$lambda_kinesis_firehose_s3_destination_arn" \
	    --capabilities CAPABILITY_AUTO_EXPAND,CAPABILITY_NAMED_IAM

	sleep 180
fi

if [ "$env_type" != "integration" -o "$deployment" = "lambda-stack" ]; then
	aws $ENPOINT_URL_FLAG cloudformation create-stack \
	    --template-body "file://cfn/lambda_deployment.yaml" \
	    --stack-name $lambda_stack_name \
	    --parameters \
	        ParameterKey="NetworkStackName",ParameterValue="$network_stack_name" \
	        ParameterKey="KinesisStreamName",ParameterValue="$delivery_stream_name" \
	        ParameterKey="KinesisFirehoseName",ParameterValue="$lambda_kinesis_firehose_stream_name" \
	        ParameterKey="S3BucketWithCode",ParameterValue="$lambda_kinesis_stream_processor_bucket" \
	        ParameterKey="S3KeyArtifact",ParameterValue="$lambda_kinesis_stream_processor_prefix" \
	        ParameterKey="LambdaArtifactVersion",ParameterValue="$lambda_kinesis_stream_processor_version" \
	        ParameterKey="LambdaHandler",ParameterValue="$lambda_kinesis_stream_handler" \
	        ParameterKey="KinesisStreamBatchingWindowSeconds",ParameterValue="$lambda_kinesis_stream_batching_seconds" \
	        ParameterKey="LambdaRuntime",ParameterValue="$lambda_kinesis_stream_processor_runtime" \
	    --capabilities CAPABILITY_IAM

	sleep 180
fi
