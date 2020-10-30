# Streaming DB changes near real time: the AWS serverless approach.
This repo containes the code of my latest article @ LinkedIn. 
There might be changes to this repo, so if you cloned it, make sure to always pull before running, as fixes/improvements will be merged quite regularly. 
Also, feel free to improve any strange things you find in this repo by opening a PR.

# Requirements
* Python 3.7
* Java 8
* AWS SDK for Java
* Boto3
* Robotframework (for integration testing/smoke test)
* Docker (to run locally)
* Pip
* Localstack
* Junit4
* Mockito

# Execution
If you would like to run this project locally, you can use the .robot file under test/integration/integration_test.robot. This makes use of several bash
scripts to properly setup everything and run a simple test suite with mocked AWS services, some provided by Localstack community edition and some mocked
via Docker-compose. Make sure to export as environment variable the following (already set in `config_integration.sh`):
* export AWS_ACCESS_KEY_ID="foo"
* export AWS_SECRET_ACCESS_KEY="bar"
* export AWS_DEFAULT_REGION="us-east-1"

You could also run `aws configure --profile test_profile` and fill in the fields as they are prompted on screen.

Finally, you can also run it in your actual AWS account (will cost you money), just generate the access key and secret access key and configure the profile with the CLI. This would
be safer than storing this in the `config_${env}.sh` that you can find in the root of this repo.

# Running local integration test
As simple as *cd* ing into test/integration and executing the following command: `robot integration_test.robot`.

# Future work
* Make use of the data API to generate data into AuroraDB and have some data written to S3.
* Add cloudformation templates that will deploy glue crawlers and enable Athena analytics.
