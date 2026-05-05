# Quick test of the proxy script
$env:MCP_ACCESS_KEY_ID = "YOUR_AWS_ACCESS_KEY_ID"
$env:MCP_SECRET_ACCESS_KEY = "YOUR_AWS_SECRET_ACCESS_KEY"
$env:MCP_API_ENDPOINT = "https://4h8r7qhmpa.execute-api.us-east-1.amazonaws.com/"
$env:MCP_REGION = "us-east-1"

Write-Host "Testing proxy script..." -ForegroundColor Cyan

# Send an initialize request
$initRequest = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'

$initRequest | & ".\02-proxy\proxy.ps1"
