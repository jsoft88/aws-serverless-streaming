import boto3
import json
import os
import argparse


class Bootstrap(object):
	PARAM_DB_SECRET_ARN = 'secretArn'
	PARAM_DB_NAME = 'dbName'
	PARAM_DB_CLUSTER_ARN = 'dbClusterArn'

	def __init__(self, output_key_db_name, stack_name_env_key, sql_files):
		self.stack_name = os.getenv[stack_name_env_key]
		self.output_key_db_name = output_key_db_name
		self.stack_name_env_key = stack_name_env_key
		self.sql_files = sql_files

		stack = cloudformation.Stack(self.stack_name)
		self.cloudformation = boto3.resource('cloudformation')
		self.rds_data_api = boto3.client('rds-data')

		self.database_name = get_value_from_output_by_key(output_key_db_name, stack.outputs)
		self.db_cluster_arn = get_cfn_output('DatabaseClusterArn', stack.outputs)
		self.db_credentials_secrets_store_arn = get_cfn_output('DatabaseSecretArn', stack.outputs)
		
		print(f'Database info: [name={self.database_name}, cluster arn={self.db_cluster_arn}, secrets arn={self.db_credentials_secrets_store_arn}]')

	def get_value_from_output_by_key(key, outputs):
		result = [ v['OutputValue'] for v in outputs if v['OutputKey'] == key ]
		return result[0] if len(result) > 0 else ''

	def execute_sql_data_api(self, rds_client, query, **kwargs):
		print(f'Running SQL statement: {sql}')
		response = rds_client.execute_statement(
			secretArn=kwargs[PARAM_DB_SECRET_ARN],
			database=kwargs[PARAM_DB_NAME],
			resourceArn=kwargs[PARAM_DB_CLUSTER_ARN],
			sql=query
		)
		return response

	def run(self):
		params = {
			PARAM_DB_SECRET_ARN: self.db_credentials_secrets_store_arn,
			PARAM_DB_NAME: self.database_name,
			PARAM_DB_CLUSTER_ARN: self.db_cluster_arn }

		for sql_file in self.sql_files:
		with open(sql_file, 'r') as f:
			content = f.read()
			try:
				execute_sql_data_api(rds_data_api, content, **params)
			except Exception as e:
				print(f'Exception while executing statement: {e}')
				raise e


if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('--output-key-db-name', dest=output_key_db_name)
	parser.add_argument('--stack-name-env-key', dest=stack_name_env_key)
	parser.add_argument('--sql-files', nargs='+', dest=sql_files)

	args = parser.parse_args()
	boostrap = Bootstrap(args.output_key_db_name, args.stack_name_env_key, args.sql_files)
	boostrap.run()