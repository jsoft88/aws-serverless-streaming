FROM ubuntu:latest
RUN apt-get update -y
RUN apt-get install -y python3-pip python3-dev build-essential
RUN pip3 install --upgrade pip
RUN pip3 install -r ./requirements.txt
ENTRYPOINT ["python3"]
CMD ["--user", "$fetcher_env_db_username", "--password", "$fetcher_env_db_password", "--host", "$fetcher_env_db_host", "--port", "$fetcher_env_db_port", "--kinesis-stream-name", "$fetcher_env_kinesis_stream_name", "--capture-from-schema", "$fetcher_env_capture_from_schema", "--capture-from-table", "$fetcher_env_capture_from_table"]