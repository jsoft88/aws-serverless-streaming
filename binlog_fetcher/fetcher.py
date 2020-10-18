import json
import boto3
import argparse
import os

from pymysqlreplication import BinLogStreamReader
from pymysqlreplication.row_event import WriteRowsEvent

def main(host, port, user, password, kinesis_stream_name, capture_from_schema, capture_from_table):
  kinesis = boto3.client("kinesis")

  stream = BinLogStreamReader(
    connection_settings= {
      "host": host,
      "port": port,
      "user": user,
      "passwd": password},
    server_id=100,
    blocking=True,
    resume_stream=True,
    only_events=[WriteRowsEvent])

  for binlogevent in stream:
    rows = list(filter(lambda x: x['schema'] == capture_from_schema and x['table'] == capture_from_table, binlogevent.rows))
    for row in rows:
      event = {"schema": binlogevent.schema,
      "table": binlogevent.table,
      "type": type(binlogevent).__name__,
      "row": row
      }

      kinesis.put_record(StreamName=kinesis_stream_name, Data=json.dumps(event), PartitionKey="default")
      print json.dumps(event)

if __name__ == "__main__":
   parser = argparse.ArgumentParser()
   parser.add_argument('--host', dest='host')
   parser.add_argument('--port', dest='port')
   parser.add_argument('--user', dest='user')
   parser.add_argument('--password', dest='password')
   parser.add_argument('--kinesis-stream-name', dest='kinesis_stream_name')
   parser.add_argument('--capture-from-schema', dest='capture_from_schema')
   parser.add_argument('--capture-from-table', dest='capture_from_table')

   args = parser.parse_args()

   host = os.getenv[args.host]
   port = int(os.getenv[args.port])
   user = os.getenv[args.user]
   password = os.getenv[args.password]
   kinesis_stream_name = os.getenv[args.kinesis_stream_name]
   capture_from_schema = os.getenv[args.capture_from_schema]
   capture_from_table = os.getenv[args.capture_from_table]

   main(host, port, user, password, capture_from_schema, capture_from_table)