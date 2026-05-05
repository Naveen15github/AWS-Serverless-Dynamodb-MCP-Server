#!/bin/bash
# ================================================================================
# check_env.sh — Pre-flight validation for DynamoDB MCP deployment
# ================================================================================

set -e

echo "==================================================================="
echo "  DynamoDB MCP — Environment Check"
echo "==================================================================="
echo

# Check for required CLI tools
echo "Checking for required tools..."

command -v aws >/dev/null 2>&1 || {
    echo "ERROR: aws CLI not found. Install from https://aws.amazon.com/cli/" >&2
    exit 1
}

command -v terraform >/dev/null 2>&1 || {
    echo "ERROR: terraform not found. Install from https://www.terraform.io/downloads" >&2
    exit 1
}

command -v jq >/dev/null 2>&1 || {
    echo "ERROR: jq not found. Install from https://stedolan.github.io/jq/" >&2
    exit 1
}

command -v envsubst >/dev/null 2>&1 || {
    echo "ERROR: envsubst not found. Usually part of gettext package." >&2
    exit 1
}

echo "  ✓ aws"
echo "  ✓ terraform"
echo "  ✓ jq"
echo "  ✓ envsubst"
echo

# Check AWS credentials
echo "Checking AWS credentials..."

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "ERROR: AWS credentials not configured or invalid." >&2
    echo "       Run 'aws configure' or set AWS_PROFILE environment variable." >&2
    exit 1
fi

CALLER_ID=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo "$CALLER_ID" | jq -r '.Account')
USER_ARN=$(echo "$CALLER_ID" | jq -r '.Arn')

echo "  ✓ AWS Account: $ACCOUNT_ID"
echo "  ✓ Identity: $USER_ARN"
echo

echo "==================================================================="
echo "  Environment check passed!"
echo "==================================================================="
