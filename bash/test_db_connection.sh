#!/bin/bash

# run this at ./envs/dev : cd ./envs/dev/
psql -h "$(terraform output -raw rds_endpoint)" -U db_master -d record -p 5432