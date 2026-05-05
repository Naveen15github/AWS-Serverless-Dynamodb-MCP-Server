# Update MCP Configuration for DynamoDB
# This script updates your Kiro MCP settings to use the PowerShell proxy

$mcpConfigPath = "$env:USERPROFILE\.kiro\settings\mcp.json"

$config = @{
    mcpServers = @{
        dynamodb = @{
            command = "powershell.exe"
            args = @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File", "C:\Users\Naveen\Downloads\Serverless-DynamoDB-MCP\02-proxy\proxy.ps1"
            )
            env = @{
                MCP_ACCESS_KEY_ID = "YOUR_AWS_ACCESS_KEY_ID"
                MCP_SECRET_ACCESS_KEY = "YOUR_AWS_SECRET_ACCESS_KEY"
                MCP_API_ENDPOINT = "https://4h8r7qhmpa.execute-api.us-east-1.amazonaws.com/"
                MCP_REGION = "us-east-1"
            }
        }
    }
}

# Create directory if it doesn't exist
$configDir = Split-Path $mcpConfigPath -Parent
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Write configuration
$config | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigPath -Encoding UTF8

Write-Host "MCP configuration updated successfully!" -ForegroundColor Green
Write-Host "Location: $mcpConfigPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "The DynamoDB MCP server should reconnect automatically." -ForegroundColor Yellow
Write-Host "Check the MCP Logs in Kiro to verify the connection." -ForegroundColor Yellow
