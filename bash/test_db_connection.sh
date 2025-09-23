#!/bin/bash

# run this at ./envs/dev : cd ./envs/dev/
psql -h "$(terraform output -raw rds_instance_address)" -U db_master -d record -p 5432