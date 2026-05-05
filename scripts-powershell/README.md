# PowerShell Scripts

This folder contains all PowerShell scripts for the DynamoDB MCP project.

## Main Scripts

### Deployment
- **`apply.ps1`** - Full deployment script for DynamoDB MCP infrastructure
  - Runs environment checks
  - Deploys Terraform infrastructure
  - Generates proxy configuration
  - Validates deployment

### Validation
- **`validate.ps1`** - Validates the deployed infrastructure
  - Tests Lambda functions
  - Verifies API Gateway endpoints
  - Checks DynamoDB operations

## Environment Check Scripts

- **`check_env.ps1`** - Basic environment check
  - Verifies AWS CLI, Terraform, and jq are installed
  - Checks AWS credentials

- **`check_env_v2.ps1`** - Enhanced environment check
  - Additional validation checks
  - More detailed output

- **`check_env_simple.ps1`** - Simplified environment check
  - Quick validation for basic requirements

## Utility Scripts

- **`fix-time.ps1`** - Fixes Windows time synchronization issues
  - Resolves AWS signature errors caused by time drift
  - Requires Administrator privileges

- **`sync-time-and-retry.ps1`** - Syncs time and retries operations
  - Automatically syncs time and retries failed operations

- **`update-mcp-config.ps1`** - Updates MCP configuration
  - Modifies MCP server settings
  - Updates environment variables

## Testing Scripts

- **`test-proxy.ps1`** - Tests the MCP proxy functionality
  - Validates proxy connection
  - Tests tool discovery

- **`test-output.ps1`** - Tests output generation
  - Validates response formats
  - Checks error handling

## Usage

### Run from project root:
```powershell
# Full deployment
.\scripts-powershell\apply.ps1

# Environment check
.\scripts-powershell\check_env.ps1

# Fix time sync issues
.\scripts-powershell\fix-time.ps1

# Validate deployment
.\scripts-powershell\validate.ps1
```

### Run from scripts folder:
```powershell
cd scripts-powershell

# Full deployment
.\apply.ps1

# Environment check
.\check_env.ps1
```

## Requirements

- PowerShell 5.1 or later
- AWS CLI configured with valid credentials
- Terraform installed
- jq installed (for JSON processing)

## Notes

- All scripts use `$ErrorActionPreference = "Stop"` for fail-fast behavior
- Scripts are designed to work on Windows systems
- Some scripts may require Administrator privileges (e.g., `fix-time.ps1`)
