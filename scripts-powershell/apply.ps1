# ================================================================================
# apply.ps1 - Full deployment for DynamoDB MCP (PowerShell version)
# ================================================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================================="
Write-Host "  DynamoDB MCP - Full Deployment"
Write-Host "==================================================================="
Write-Host ""

# Step 1: Pre-flight checks
Write-Host "[1/4] Running environment check..."
& .\check_env_v2.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Environment check failed. Please fix the issues and try again." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Terraform deploy
Write-Host "[2/4] Deploying Lambda functions and API Gateway..."
Push-Location 01-lambdas
try {
    terraform init -upgrade
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
    
    terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
} finally {
    Pop-Location
}
Write-Host ""

# Step 3: Generate proxy config
Write-Host "[3/4] Generating proxy configuration..."

$secretJson = aws secretsmanager get-secret-value --secret-id dynamodb-mcp-proxy --query SecretString --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to retrieve secret from AWS Secrets Manager" -ForegroundColor Red
    exit 1
}

$secret = $secretJson | ConvertFrom-Json

$accessKeyId = $secret.access_key_id
$secretAccessKey = $secret.secret_access_key
$apiEndpoint = $secret.api_endpoint
$region = $secret.region

# Get current directory path with forward slashes for bash compatibility
$currentPath = (Get-Location).Path -replace '\\', '/'

# Create proxy config for bash using hashtable and ConvertTo-Json
$config = @{
    mcpServers = @{
        dynamodb = @{
            command = "bash"
            args = @("$currentPath/02-proxy/proxy.sh")
            env = @{
                MCP_ACCESS_KEY_ID = $accessKeyId
                MCP_SECRET_ACCESS_KEY = $secretAccessKey
                MCP_API_ENDPOINT = $apiEndpoint
                MCP_REGION = $region
            }
        }
    }
}

$configJson = $config | ConvertTo-Json -Depth 10
$configJson | Out-File -FilePath "configs\claude_desktop_config_sh.json" -Encoding UTF8

Write-Host "  Generated: configs\claude_desktop_config_sh.json"
Write-Host ""

# Step 4: Validation
Write-Host "[4/4] Validation..."
Write-Host "  Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "==================================================================="
Write-Host "  Deployment complete!"
Write-Host "==================================================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Copy the contents of configs\claude_desktop_config_sh.json"
Write-Host "  2. Add to your Claude Desktop config file"
Write-Host "  3. Restart Claude Desktop"
Write-Host ""
