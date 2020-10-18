#!/bin/bash

set -e

. "../config-${env_type}.sh"

python3 create_schema.py --output-key-db-name 