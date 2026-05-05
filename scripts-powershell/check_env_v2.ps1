Write-Output "==================================================================="
Write-Output "  DynamoDB MCP - Environment Check"
Write-Output "==================================================================="
Write-Output ""
Write-Output "Checking for required tools..."
Write-Output ""

$allToolsFound = $true

# Check AWS CLI
Write-Output "Checking aws..."
if (Get-Command aws -ErrorAction SilentlyContinue) {
    Write-Output "  [OK] aws"
} else {
    Write-Output "  [X] aws CLI not found"
    Write-Output "      Install from: https://aws.amazon.com/cli/"
    $allToolsFound = $false
}

# Check Terraform
Write-Output "Checking terraform..."
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    Write-Output "  [OK] terraform"
} else {
    Write-Output "  [X] terraform not found"
    Write-Output "      Install from: https://www.terraform.io/downloads"
    $allToolsFound = $false
}

# Check jq
Write-Output "Checking jq..."
if (Get-Command jq -ErrorAction SilentlyContinue) {
    Write-Output "  [OK] jq"
} else {
    Write-Output "  [X] jq not found"
    Write-Output "      Install via: choco install jq"
    Write-Output "      Or from: https://stedolan.github.io/jq/"
    $allToolsFound = $false
}

if (-not $allToolsFound) {
    Write-Output ""
    Write-Output "ERROR: Some required tools are missing."
    Write-Output "Please install the missing tools and run this script again."
    Write-Output ""
    exit 1
}

Write-Output ""
Write-Output "Checking AWS credentials..."
Write-Output ""

try {
    $callerIdentity = aws sts get-caller-identity 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        throw "AWS credentials check failed"
    }
    
    $callerIdJson = $callerIdentity | ConvertFrom-Json
    $accountId = $callerIdJson.Account
    $userArn = $callerIdJson.Arn
    
    Write-Output "  [OK] AWS Account: $accountId"
    Write-Output "  [OK] Identity: $userArn"
} catch {
    Write-Output "  [X] AWS credentials not configured or invalid"
    Write-Output "      Run 'aws configure' to set up credentials"
    Write-Output "      Or set AWS_PROFILE environment variable"
    Write-Output ""
    exit 1
}

Write-Output ""
Write-Output "==================================================================="
Write-Output "  Environment check PASSED!"
Write-Output "==================================================================="
Write-Output ""
Write-Output "You can now proceed with deployment:"
Write-Output "  bash apply.sh      - Deploy the infrastructure"
Write-Output "  bash validate.sh   - Validate the deployment"
