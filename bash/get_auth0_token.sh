#!/bin/bash

# Configuration - Sources from env.properties if available
ENV_FILE="$(dirname "$0")/../springboot_cqrs_command/env.properties"

if [ -f "$ENV_FILE" ]; then
    # Simple way to parse properties file
    AUTH0_DOMAIN=$(grep '^AUTH0_DOMAIN=' "$ENV_FILE" | cut -d'=' -f2)
    AUTH0_CLIENT_ID=$(grep '^AUTH0_CLIENT_ID=' "$ENV_FILE" | cut -d'=' -f2)
    AUTH0_CLIENT_SECRET=$(grep '^AUTH0_CLIENT_SECRET=' "$ENV_FILE" | cut -d'=' -f2)
    AUTH0_AUDIENCE=$(grep '^AUTH0_AUDIENCE=' "$ENV_FILE" | cut -d'=' -f2)
fi

# Override with environment variables if present
AUTH0_DOMAIN=${AUTH0_DOMAIN:-"your-tenant.region.auth0.com"}
AUTH0_CLIENT_ID=${AUTH0_CLIENT_ID:-"YOUR_CLIENT_ID"}
AUTH0_CLIENT_SECRET=${AUTH0_CLIENT_SECRET:-"YOUR_CLIENT_SECRET"}
AUTH0_AUDIENCE=${AUTH0_AUDIENCE:-"YOUR_API_IDENTIFIER"}

if [ "$AUTH0_CLIENT_ID" = "YOUR_CLIENT_ID" ]; then
    echo "Error: AUTH0_CLIENT_ID not set in $ENV_FILE or environment" >&2
    exit 1
fi

# Fetch Access Token
ACCESS_TOKEN=$(
curl --request POST \
  --url https://choudai-matketplace.jp.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id":"koujceycuuwjxoCKqjJjsimCfBqgJ4ev",
    "client_secret":"VzEfL8QC1Ts-PHZ98ZL0Kq5VGKm4INaLndlpngVLbae2VATV5Luj1eW8WNs57dOt",
    "audience":"https://accounting-cqrs-project-381492877.ap-northeast-1.elb.amazonaws.com",
    "grant_type":"client_credentials"
  }')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Failed to fetch access token from Auth0" >&2
    exit 1
fi

echo "${ACCESS_TOKEN}"
