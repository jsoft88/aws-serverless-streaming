*** Settings ***
Library           Process
Suite Setup       Run Process    bash                                       ./integration_setup.sh                  shell=True      cwd=${CURDIR}                                                                                               stderr=${CURDIR}/integration-setup-stderr       stdout=${CURDIR}/integration-setup-stdout
Suite Teardown    Run Process    bash                                       ./integration_testing_finalize.sh       shell=True      cwd=${CURDIR}

*** Test Cases ***
Test deployment of Network stack
    ${network_stack_status} =             Run Process                            bash                                                                                                                                                           ./deploy_rds.sh         integration                                                                            network-stack                        shell=True              stderr=${CURDIR}/network-stack-stderr              stdout=${CURDIR}/network-stack-stdout           cwd=${CURDIR}/../../
    Should Be Equal As Integers           ${network_stack_status.rc}             0

Test deployment of Kinesis stream stack
    ${kinesis_stream_stack_status} =      Run Process                            bash                                                                                                                                                           ./deploy_rds.sh     integration                                                                            kinesis-stream-stack                     shell=True              stderr=${CURDIR}/kinesis-stream-stack-stderr       stdout=${CURDIR}/kinesis-stream-stack-stdout    cwd=${CURDIR}/../../
    Should Be Equal As Integers           ${kinesis_stream_stack_status.rc}      0

Test deployment of Kinesis firehose stack
    ${kinesis_firehose_stack_status} =    Run Process                            bash                                                                                                                                                           ./deploy_rds.sh     integration                                                                           kinesis-firehose-stack                    shell=True              stderr=${CURDIR}/kinesis-firehose-stack-stderr     stdout=${CURDIR}/kinesis-firehose-stack-stdout  cwd=${CURDIR}/../../
    Should Be Equal As Integers           ${kinesis_firehose_stack_status.rc}    0

Test deployment of Lambda stack
    ${lambda_stack_status} =              Run Process                            bash                                                                                                                                                           ./deploy_rds.sh     integration                                                                            lambda-stack                             shell=True              stderr=${CURDIR}/lambda-stack-stderr               stdout=${CURDIR}/lambda-stack-stdout            cwd=${CURDIR}/../../
    Should Be Equal As Integers           ${lambda_stack_status.rc}              0

E2E run must end with files in s3
    # Start setup
    ${docker_compose_status} =            Run Process                            bash                                                                                                                                                           ./test/integration/run-docker-compose.sh    integration                                                     shell=True                              stderr=${CURDIR}/lambda-stack-stderr               stdout=${CURDIR}/lambda-stack-stdout            cwd=${CURDIR}/../../                                                                                                                                            shell=True              stderr=${CURDIR}/docker-compose-stderr             stdout=${CURDIR}/docker-compose-stdout
    Should Be Equal As Integers           ${docker_compose_status.rc}            0
    Sleep                                 120s

