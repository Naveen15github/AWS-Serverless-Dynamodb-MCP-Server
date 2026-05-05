# ================================================================================
# File: proxy.ps1
#
# Purpose:
#   MCP stdio proxy for the DynamoDB serverless API (PowerShell version for Windows)
# ================================================================================

$ErrorActionPreference = "Stop"

# ================================================================================
# Configuration
# ================================================================================

$ACCESS_KEY = $env:MCP_ACCESS_KEY_ID
$SECRET_KEY = $env:MCP_SECRET_ACCESS_KEY
$API_ENDPOINT = $env:MCP_API_ENDPOINT
$REGION = if ($env:MCP_REGION) { $env:MCP_REGION } else { "us-east-1" }
$MCP_USER = $env:USERNAME

if (-not $ACCESS_KEY -or -not $SECRET_KEY -or -not $API_ENDPOINT) {
    Write-Error "Missing required environment variables"
    exit 1
}

# ================================================================================
# Tool registry
# ================================================================================

$TOOL_ROUTES = @{}
$TOOLS_JSON = "[]"

# ================================================================================
# AWS SigV4 signing helpers
# ================================================================================

function Get-SHA256Hash {
    param([string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

function Get-HmacSHA256 {
    param([byte[]]$Key, [string]$Text)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = $Key
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    return $hmac.ComputeHash($bytes)
}

function Invoke-SignedRequest {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Body = ""
    )
    
    $service = "execute-api"
    $now = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
    $dateStamp = $now.Substring(0, 8)
    
    $uri = [System.Uri]$Url
    $hostname = $uri.Host
    $uriPath = $uri.PathAndQuery
    
    if ($Method -eq "GET") {
        $payloadHash = Get-SHA256Hash ""
        $canonicalHeaders = "host:$hostname`nx-amz-date:$now`nx-mcp-user:$MCP_USER`n"
        $signedHeaders = "host;x-amz-date;x-mcp-user"
    } else {
        $effectiveBody = if ($Body) { $Body } else { "{}" }
        $payloadHash = Get-SHA256Hash $effectiveBody
        $canonicalHeaders = "content-type:application/json`nhost:$hostname`nx-amz-date:$now`nx-mcp-user:$MCP_USER`n"
        $signedHeaders = "content-type;host;x-amz-date;x-mcp-user"
        $Body = $effectiveBody
    }
    
    $canonicalRequest = "$Method`n$uriPath`n`n$canonicalHeaders`n$signedHeaders`n$payloadHash"
    $credentialScope = "$dateStamp/$REGION/$service/aws4_request"
    $crHash = Get-SHA256Hash $canonicalRequest
    $stringToSign = "AWS4-HMAC-SHA256`n$now`n$credentialScope`n$crHash"
    
    $kDate = Get-HmacSHA256 ([System.Text.Encoding]::UTF8.GetBytes("AWS4$SECRET_KEY")) $dateStamp
    $kRegion = Get-HmacSHA256 $kDate $REGION
    $kService = Get-HmacSHA256 $kRegion $service
    $kSigning = Get-HmacSHA256 $kService "aws4_request"
    
    $signatureBytes = Get-HmacSHA256 $kSigning $stringToSign
    $signature = [System.BitConverter]::ToString($signatureBytes).Replace("-", "").ToLower()
    
    $authHeader = "AWS4-HMAC-SHA256 Credential=$ACCESS_KEY/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"
    
    $headers = @{
        "Authorization" = $authHeader
        "x-amz-date" = $now
        "x-mcp-user" = $MCP_USER
    }
    
    if ($Method -eq "POST") {
        $headers["Content-Type"] = "application/json"
        return Invoke-RestMethod -Uri $Url -Method Post -Headers $headers -Body $Body
    } else {
        return Invoke-RestMethod -Uri $Url -Method Get -Headers $headers
    }
}

# ================================================================================
# Tool discovery
# ================================================================================

function Load-ToolRegistry {
    $url = "$API_ENDPOINT/tools".TrimEnd('/')
    Write-Host "NOTE: Discovering tools from $url ..." -ForegroundColor Yellow
    
    try {
        $registry = Invoke-SignedRequest -Method "GET" -Url $url
        
        foreach ($tool in $registry) {
            $TOOL_ROUTES[$tool.name] = $tool.route
        }
        
        $script:TOOLS_JSON = $registry | ConvertTo-Json -Depth 10 -Compress
        
        Write-Host "NOTE: Discovered $($registry.Count) tool(s)." -ForegroundColor Yellow
    } catch {
        Write-Host "ERROR: Tool discovery failed: $_" -ForegroundColor Red
        exit 1
    }
}

# ================================================================================
# JSON-RPC helpers
# ================================================================================

function Send-Response {
    param([object]$Id, [object]$Result)
    $response = @{
        jsonrpc = "2.0"
        id = $Id
        result = $Result
    } | ConvertTo-Json -Depth 10 -Compress
    Write-Output $response
}

function Send-Error {
    param([object]$Id, [int]$Code, [string]$Message)
    $response = @{
        jsonrpc = "2.0"
        id = $Id
        error = @{
            code = $Code
            message = $Message
        }
    } | ConvertTo-Json -Depth 10 -Compress
    Write-Output $response
}

# ================================================================================
# MCP method handlers
# ================================================================================

function Handle-Initialize {
    param([object]$Id)
    $result = @{
        protocolVersion = "2025-11-25"
        capabilities = @{ tools = @{} }
        serverInfo = @{
            name = "dynamodb-mcp"
            version = "1.0.0"
        }
    }
    Send-Response -Id $Id -Result $result
}

function Handle-ToolsList {
    param([object]$Id)
    $tools = $TOOLS_JSON | ConvertFrom-Json
    # Ensure tools is an array
    if ($tools -isnot [System.Array]) {
        $tools = @($tools)
    }
    $result = @{ tools = @($tools) }
    Send-Response -Id $Id -Result $result
}

function Handle-ToolsCall {
    param([object]$Id, [object]$Params)
    
    $toolName = $Params.name
    if (-not $toolName) {
        Send-Error -Id $Id -Code -32602 -Message "Missing required parameter: name"
        return
    }
    
    $route = $TOOL_ROUTES[$toolName]
    if (-not $route) {
        Send-Error -Id $Id -Code -32602 -Message "Unknown tool: $toolName"
        return
    }
    
    $url = "$API_ENDPOINT$route".Replace("//", "/").Replace(":/", "://")
    $arguments = if ($Params.arguments) { $Params.arguments | ConvertTo-Json -Depth 10 -Compress } else { "{}" }
    
    try {
        $text = Invoke-SignedRequest -Method "POST" -Url $url -Body $arguments
        $result = @{
            content = @(
                @{
                    type = "text"
                    text = $text
                }
            )
        }
        Send-Response -Id $Id -Result $result
    } catch {
        Send-Error -Id $Id -Code -32603 -Message "Tool invocation failed: $_"
    }
}

# ================================================================================
# Main
# ================================================================================

Write-Host "NOTE: DynamoDB MCP proxy started." -ForegroundColor Yellow
Write-Host "NOTE: Endpoint: $API_ENDPOINT  Region: $REGION" -ForegroundColor Yellow

Load-ToolRegistry

while ($true) {
    $line = [Console]::In.ReadLine()
    if ($null -eq $line) { break }
    if ($line.Trim() -eq "") { continue }
    
    try {
        $request = $line | ConvertFrom-Json
        $method = $request.method
        $id = $request.id
        $params = $request.params
        
        switch ($method) {
            "initialize" {
                if ($null -ne $id) { Handle-Initialize -Id $id }
            }
            "notifications/initialized" {
                # No response needed
            }
            "tools/list" {
                if ($null -ne $id) { Handle-ToolsList -Id $id }
            }
            "tools/call" {
                if ($null -ne $id) { Handle-ToolsCall -Id $id -Params $params }
            }
            default {
                if ($null -ne $id) {
                    Send-Error -Id $id -Code -32601 -Message "Method not found: $method"
                }
            }
        }
    } catch {
        Write-Host "WARN: Failed to parse JSON: $line" -ForegroundColor Yellow
    }
}

Write-Host "NOTE: MCP proxy exiting." -ForegroundColor Yellow
