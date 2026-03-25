#!/bin/bash

# Configuration
PORT=8181
CONTEXT_PATH="/command"
ENDPOINT="/ledger"
BASE_URL="http://localhost:${PORT}${CONTEXT_PATH}${ENDPOINT}"

# Check for JWT token argument
if [ -z "$1" ]; then
    echo "No token provided, attempting to fetch from Auth0..."
    TOKEN=$(sh "$(dirname "$0")/get_auth0_token.sh")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch token. Usage: sh $0 <YOUR_JWT_TOKEN>"
        exit 1
    fi
else
    TOKEN=$1
fi

# Curl command with balanced ledger items
# Debit 1000.0 (COA 101) and Credit 1000.0 (COA 201)
curl -X POST "$BASE_URL" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $TOKEN" \
     -d '{
       "date": "'"$(date +%Y-%m-%d)"'",
       "description": "Testing new ledger creation via script",
       "ledgerItems": [
         {
           "coa": 101,
           "amount": 1000.0,
           "balanceType": "Debit"
         },
         {
           "coa": 201,
           "amount": 1000.0,
           "balanceType": "Credit"
         }
       ],
       "timestamp": "'"$(date +%Y-%m-%dT%H:%M:%S)"'"
     }'
