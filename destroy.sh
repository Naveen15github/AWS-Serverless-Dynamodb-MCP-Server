#!/bin/bash
# ================================================================================
# destroy.sh — Teardown DynamoDB MCP infrastructure
# ================================================================================

set -e

echo "==================================================================="
echo "  DynamoDB MCP — Infrastructure Teardown"
echo "==================================================================="
echo

read -p "This will destroy all deployed resources. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

cd 01-lambdas
terraform destroy -auto-approve
cd ..

echo
echo "==================================================================="
echo "  Teardown complete!"
echo "==================================================================="
