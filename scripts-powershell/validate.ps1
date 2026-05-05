# ================================================================================
# validate.ps1 - Validation tests for DynamoDB MCP (PowerShell version)
# ================================================================================

$ErrorActionPreference = "Continue"

Write-Host "==================================================================="
Write-Host "  DynamoDB MCP - Validation Tests"
Write-Host "==================================================================="
Write-Host ""

Write-Host "Testing Lambda functions via direct invocation..."
Write-Host ""

function Test-Lambda {
    param(
        [string]$FunctionName,
        [hashtable]$Body = @{}
    )

    Write-Host "  Testing $FunctionName... " -NoNewline

    $tempFile = [System.IO.Path]::GetTempFileName()
    
    # Create API Gateway event structure
    $bodyJson = $Body | ConvertTo-Json -Compress -Depth 10
    $event = @{
        body = $bodyJson
        headers = @{
            "x-mcp-user" = "validation-test"
        }
    } | ConvertTo-Json -Compress -Depth 10
    
    try {
        $null = aws lambda invoke --function-name $FunctionName --payload $event --cli-binary-format raw-in-base64-out $tempFile 2>&1

        if ($LASTEXITCODE -eq 0) {
            $output = Get-Content $tempFile -Raw | ConvertFrom-Json
            $statusCode = $output.statusCode
            
            if ($statusCode -eq 200) {
                Write-Host "OK" -ForegroundColor Green
            } elseif ($statusCode -eq 400) {
                Write-Host "OK (expected error)" -ForegroundColor Yellow
            } else {
                Write-Host "FAILED (status code: $statusCode)" -ForegroundColor Red
            }
        } else {
            Write-Host "FAILED (invocation failed)" -ForegroundColor Red
        }
    } catch {
        Write-Host "FAILED (error: $($_.Exception.Message))" -ForegroundColor Red
    } finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

# Test tool registry
Test-Lambda -FunctionName "dynamodb-tools"

# Test list tables
Test-Lambda -FunctionName "dynamodb-list-tables"

# Test describe table (will fail if table doesn't exist, but Lambda should handle it)
Test-Lambda -FunctionName "dynamodb-describe-table" -Payload '{"table_name":"test-table"}'

# Test count items
Test-Lambda -FunctionName "dynamodb-count-items" -Payload '{"table_name":"test-table"}'

# Test get item (will fail if table doesn't exist, but Lambda should handle it)
Test-Lambda -FunctionName "dynamodb-get-item" -Payload '{"table_name":"test-table","key":{"id":"test"}}'

Write-Host ""
Write-Host "==================================================================="
Write-Host "  Validation complete!"
Write-Host "==================================================================="
Write-Host ""
Write-Host "Note: Some tests may show errors if you don't have DynamoDB tables"
Write-Host "      created yet. The Lambda functions are working correctly if they"
Write-Host "      return proper error messages."
Write-Host ""
