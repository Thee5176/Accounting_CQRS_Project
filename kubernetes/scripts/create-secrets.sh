#!/bin/bash

##############################################################################
# Kubernetes Secret Generator from env.properties
# This script reads from env.properties and creates Kubernetes secrets
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/env.properties"
NAMESPACE="accounting-core"
SECRET_DIR="$SCRIPT_DIR/../secret"

# Check if env.properties exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Error: env.properties not found at $ENV_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Kubernetes Secret Generator${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Source file: $ENV_FILE${NC}"
echo -e "${YELLOW}Namespace: $NAMESPACE${NC}"
echo ""

# Function to encode value in base64
encode_base64() {
    echo -n "$1" | base64 -w 0
}

# Function to generate secret YAML
generate_springboot_secret() {
    echo -e "${BLUE}Generating springboot-config secret...${NC}"
    
    # Extract variables
    DB_URL=$(grep "^DB_URL=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    DB_USERNAME=$(grep "^DB_USERNAME=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    DB_PASSWORD=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    AUTH0_DOMAIN=$(grep "^AUTH0_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    AUTH0_CLIENT_ID=$(grep "^AUTH0_CLIENT_ID=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    AUTH0_CLIENT_SECRET=$(grep "^AUTH0_CLIENT_SECRET=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    AUTH0_AUDIENCE=$(grep "^AUTH0_AUDIENCE=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$DB_URL" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
        echo -e "${RED}✗ Missing required database variables${NC}"
        return 1
    fi
    
    cat > "$SECRET_DIR/springboot-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: springboot-config
  namespace: $NAMESPACE
type: Opaque
data:
  DB_URL: $(encode_base64 "$DB_URL")
  DB_USERNAME: $(encode_base64 "$DB_USERNAME")
  DB_PASSWORD: $(encode_base64 "$DB_PASSWORD")
  AUTH0_DOMAIN: $(encode_base64 "$AUTH0_DOMAIN")
  AUTH0_CLIENT_ID: $(encode_base64 "$AUTH0_CLIENT_ID")
  AUTH0_CLIENT_SECRET: $(encode_base64 "$AUTH0_CLIENT_SECRET")
  AUTH0_AUDIENCE: $(encode_base64 "$AUTH0_AUDIENCE")
EOF
    
    echo -e "${GREEN}✓ springboot-secret.yaml generated${NC}"
}

generate_react_secret() {
    echo -e "${BLUE}Generating react-config secret...${NC}"
    
    # Extract variables
    AUTH0_DOMAIN=$(grep "^AUTH0_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    AUTH0_CLIENT_ID=$(grep "^AUTH0_CLIENT_ID=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    AUTH0_CLIENT_SECRET=$(grep "^AUTH0_CLIENT_SECRET=" "$ENV_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$AUTH0_DOMAIN" ] || [ -z "$AUTH0_CLIENT_ID" ]; then
        echo -e "${RED}✗ Missing required Auth0 variables${NC}"
        return 1
    fi
    
    cat > "$SECRET_DIR/react-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: react-config
  namespace: $NAMESPACE
type: Opaque
data:
  AUTH0_DOMAIN: $(encode_base64 "$AUTH0_DOMAIN")
  AUTH0_CLIENT_ID: $(encode_base64 "$AUTH0_CLIENT_ID")
  AUTH0_CLIENT_SECRET: $(encode_base64 "$AUTH0_CLIENT_SECRET")
EOF
    
    echo -e "${GREEN}✓ react-secret.yaml generated${NC}"
}

# Function to apply secrets
apply_secrets() {
    echo ""
    echo -e "${BLUE}Applying secrets to Kubernetes...${NC}"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
    
    # Apply secrets
    if kubectl apply -f "$SECRET_DIR/springboot-secret.yaml" && \
       kubectl apply -f "$SECRET_DIR/react-secret.yaml"; then
        echo -e "${GREEN}✓ Secrets applied successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to apply secrets${NC}"
        return 1
    fi
}

# Function to verify secrets
verify_secrets() {
    echo ""
    echo -e "${BLUE}Verifying secrets in Kubernetes...${NC}"
    
    echo -e "${YELLOW}Secrets in namespace '$NAMESPACE':${NC}"
    kubectl get secrets -n "$NAMESPACE" -o wide || true
}

# Main execution
main() {
    # Generate secrets
    generate_springboot_secret || exit 1
    generate_react_secret || exit 1
    
    # Apply secrets
    read -p "Apply secrets to Kubernetes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_secrets || exit 1
        verify_secrets
    else
        echo -e "${YELLOW}Secrets generated but not applied. Run 'kubectl apply -f kubernetes/secret/' to apply.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Done!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
}

main "$@"
