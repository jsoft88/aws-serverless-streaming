*** Settings ***
Library           Process
Suite Setup       Run Process    bash                                       ./integration_setup.sh                  shell=True      cwd=${CURDIR}                                                                                               stderr=${CURDIR}/integration-setup-stderr       stdout=${CURDIR}/integration-setup-stdout
Suite Teardown    Run Process    bash                                       ./integration_testing_finalize.sh       shell=True      cwd=${CURDIR}

*** Test Cases ***
Test deployment of Network stack
    ${network_stack_status} =             Run Process                            bash                                                                                                                                                           ./deploy_rds.sh         integration                                                                            network-stack                             shell=True              stderr=${CURDIR}/network-stack-stderr              stdout=${CURDIR}/network-stack-stdout           cwd=${CURDIR}/../../
    Should Be Equal As Integers           ${network_stack_status.rc}             0

Test deployment of Kinesis stream stack
    ${kinesis_stream_stack_status} =      Run Process                            bash                                                                                                                                                           ../../deploy_rds.sh     integration                                                                            kinesis-stream-stack                      shell=True              stderr=${CURDIR}/kinesis-stream-stack-stderr       stdout=${CURDIR}/kinesis-stream-stack-stdout
    Should Be Equal As Integers           ${kinesis_stream_stack_status.rc}      0

Test deployment of Kinesis firehose stack
    ${kinesis_firehose_stack_status} =    Run Process                            bash                                                                                                                                                           ../../deploy_rds.sh     integration                                                                           kinesis-firehose-stack                     shell=True              stderr=${CURDIR}/kinesis-firehose-stack-stderr     stdout=${CURDIR}/kinesis-firehose-stack-stdout
    Should Be Equal As Integers           ${kinesis_firehose_stack_status.rc}    0

Test deployment of Lambda stack
    ${lambda_stack_status} =              Run Process                            bash                                                                                                                                                           ../../deploy_rds.sh     integration                                                                            lambda-stack                              shell=True              stderr=${CURDIR}/lambda-stack-stderr               stdout=${CURDIR}/lambda-stack-stdout
    Should Be Equal As Integers           ${lambda_stack_status.rc}              0

E2E run must end with files in s3
    # Create secret string for password in SSM
    ${add_secret_status} =                Run Process                            aws ssm                                                                                                                                                        put-parameter          --type SecureString                                                                    --value 123456            --name "$db_password_secret_ssm_key"      --endpoint-url http://localhost:4566      shell=True
    Should Be Equal As Integers           ${add_secret_status.rc}                0
    # Create bucket for lambdas and firehose destination
    ${add_firehose_bucket} =              Run Process                            aws s3                                                                                                                                                         mb                     "s3://$lambda_kinesis_firehose_s3_bucket" --endpoint-url http://localhost:4566         shell=True
    Should Be Equal As Integers           ${add_firehose_bucket.rc}              0
    # Create bucket for lambda function
    ${add_firehose_bucket} =              Run Process                            aws s3                                                                                                                                                         mb                     "s3://$lambda_kinesis_stream_processor_bucket" --endpoint-url http://localhost:4566    shell=True
    # Build lambda jar
    ${jar_build_status} =                 Run Process                            mvn                                                                                                                                                            clean                  package                                                                                -DskipTests=true          -DoutputDirectory=../../lambda/target/      shell=True
    Should Be Equal As Integers           ${jar_build_status.rc}                 0
    # upload lambda jar to s3
    ${jar_to_s3_status} =                 Run Process                            aws s3 cp ../../lambda/target/serverlessDBStreaming-1.0-SNAPSHOT.jar "s3://$lambda_kinesis_stream_processor_bucket/$lambda_kinesis_stream_processor_prefix"    shell=True
    Should Be Equal As Integers           ${jar_to_s3_status.rc}                 0
    # Start setup
    ${docker_compose_status} =            Run Process                          docker-compose                                                                                                                                                 up                      shell=True
    Should Be Equal As Integers           ${docker_compose_status.rc}            0
    Sleep                                 120s

