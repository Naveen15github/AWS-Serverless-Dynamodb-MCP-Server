#!/bin/bash
# ================================================================================
# apply.sh — Full deployment for DynamoDB MCP
# ================================================================================

set -e

echo "==================================================================="
echo "  DynamoDB MCP — Full Deployment"
echo "==================================================================="
echo

# Step 1: Pre-flight checks
echo "[1/4] Running environment check..."
./check_env.sh
echo

# Step 2: Terraform deploy
echo "[2/4] Deploying Lambda functions and API Gateway..."
cd 01-lambdas
terraform init -upgrade
terraform apply -auto-approve
cd ..
echo

# Step 3: Generate proxy config
echo "[3/4] Generating proxy configuration..."

SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id dynamodb-mcp-proxy \
    --query SecretString \
    --output text)

export MCP_ACCESS_KEY_ID=$(echo "$SECRET_JSON" | jq -r '.access_key_id')
export MCP_SECRET_ACCESS_KEY=$(echo "$SECRET_JSON" | jq -r '.secret_access_key')
export MCP_API_ENDPOINT=$(echo "$SECRET_JSON" | jq -r '.api_endpoint')
export MCP_REGION=$(echo "$SECRET_JSON" | jq -r '.region')

# Create proxy config for bash
cat > configs/claude_desktop_config_sh.json <<EOF
{
  "mcpServers": {
    "dynamodb": {
      "command": "bash",
      "args": ["$(pwd)/02-proxy/proxy.sh"],
      "env": {
        "MCP_ACCESS_KEY_ID": "${MCP_ACCESS_KEY_ID}",
        "MCP_SECRET_ACCESS_KEY": "${MCP_SECRET_ACCESS_KEY}",
        "MCP_API_ENDPOINT": "${MCP_API_ENDPOINT}",
        "MCP_REGION": "${MCP_REGION}"
      }
    }
  }
}
EOF

echo "  ✓ Generated: configs/claude_desktop_config_sh.json"
echo

# Step 4: Validation
echo "[4/4] Running validation tests..."
./validate.sh
echo

echo "==================================================================="
echo "  Deployment complete!"
echo "==================================================================="
echo
echo "Next steps:"
echo "  1. Copy the contents of configs/claude_desktop_config_sh.json"
echo "  2. Add to your Claude Desktop config file"
echo "  3. Restart Claude Desktop"
echo
