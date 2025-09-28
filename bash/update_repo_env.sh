#!/bin/bash

# run this at ./envs/dev : cd ./envs/dev/
gh secret set EC2_PUBLIC_IP --repo Thee5176/Accounting_CQRS_Project --env "AWS and Supabase" --body "$(terraform output -raw ec2_instance_public_ip | tr -d '\n')"