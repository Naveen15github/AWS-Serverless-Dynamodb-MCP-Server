#!/bin/bash
# ================================================================================
# File: proxy.sh
#
# Purpose:
#   MCP stdio proxy for the DynamoDB serverless API. Reads JSON-RPC 2.0
#   messages from stdin, signs POST requests to API Gateway with AWS SigV4,
#   and writes tool results back to stdout.
#
# Dependencies:
#   bash 4+, curl, jq, openssl
#
# Required environment variables:
#   MCP_ACCESS_KEY_ID      IAM access key for the dynamodb-mcp-proxy user
#   MCP_SECRET_ACCESS_KEY  IAM secret key for the dynamodb-mcp-proxy user
#   MCP_API_ENDPOINT       API Gateway invoke URL (no trailing slash)
#   MCP_REGION             AWS region (default: us-east-1)
# ================================================================================

set -euo pipefail

# ================================================================================
# Configuration
# ================================================================================

ACCESS_KEY="${MCP_ACCESS_KEY_ID:?MCP_ACCESS_KEY_ID is required}"
SECRET_KEY="${MCP_SECRET_ACCESS_KEY:?MCP_SECRET_ACCESS_KEY is required}"
API_ENDPOINT="${MCP_API_ENDPOINT:?MCP_API_ENDPOINT is required}"
REGION="${MCP_REGION:-us-east-1}"
MCP_USER="${USER:-$(whoami)}"

# ================================================================================
# Tool registry — populated at startup from GET /tools
# ================================================================================

declare -A TOOL_ROUTES
TOOLS_JSON='[]'

# ================================================================================
# SigV4 signing helpers
# ================================================================================

sha256_hex() {
    echo -n "$1" | openssl dgst -sha256 -hex | sed 's/^.*= //'
}

hmac_sha256_str() {
    local key="$1" data="$2"
    echo -n "$data" | openssl dgst -sha256 -mac HMAC -macopt "key:${key}" -hex | sed 's/^.*= //'
}

hmac_sha256_hex() {
    local hex_key="$1" data="$2"
    echo -n "$data" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:${hex_key}" -hex | sed 's/^.*= //'
}

invoke_signed_request() {
    local method="$1"
    local url="$2"
    local body="${3:-}"
    local service="execute-api"

    local now date_stamp host uri_path
    now=$(date -u '+%Y%m%dT%H%M%SZ')
    date_stamp="${now:0:8}"
    host=$(echo "$url" | sed 's|https://||' | cut -d'/' -f1)
    uri_path=$(echo "$url" | sed "s|https://${host}||")

    local payload_hash canonical_headers signed_headers canonical_request

    if [[ "$method" == "GET" ]]; then
        payload_hash=$(sha256_hex "")
        canonical_headers="host:${host}
x-amz-date:${now}
x-mcp-user:${MCP_USER}
"
        signed_headers="host;x-amz-date;x-mcp-user"
    else
        local effective_body="${body:-{\}}"
        payload_hash=$(sha256_hex "$effective_body")
        canonical_headers="content-type:application/json
host:${host}
x-amz-date:${now}
x-mcp-user:${MCP_USER}
"
        signed_headers="content-type;host;x-amz-date;x-mcp-user"
        body="$effective_body"
    fi

    canonical_request="${method}
${uri_path}

${canonical_headers}
${signed_headers}
${payload_hash}"

    local credential_scope cr_hash string_to_sign
    credential_scope="${date_stamp}/${REGION}/${service}/aws4_request"
    cr_hash=$(sha256_hex "$canonical_request")
    string_to_sign="AWS4-HMAC-SHA256
${now}
${credential_scope}
${cr_hash}"

    local k_date k_region k_service k_signing signature
    k_date=$(hmac_sha256_str    "AWS4${SECRET_KEY}" "$date_stamp")
    k_region=$(hmac_sha256_hex  "$k_date"           "$REGION")
    k_service=$(hmac_sha256_hex "$k_region"         "$service")
    k_signing=$(hmac_sha256_hex "$k_service"        "aws4_request")
    signature=$(hmac_sha256_hex "$k_signing"        "$string_to_sign")

    local auth_header="AWS4-HMAC-SHA256 Credential=${ACCESS_KEY}/${credential_scope}, SignedHeaders=${signed_headers}, Signature=${signature}"

    if [[ "$method" == "GET" ]]; then
        curl -s -X GET "$url" \
            -H "Authorization: ${auth_header}" \
            -H "x-amz-date: ${now}" \
            -H "x-mcp-user: ${MCP_USER}" \
            < /dev/null
    else
        curl -s -X POST "$url" \
            -H "Authorization: ${auth_header}" \
            -H "x-amz-date: ${now}" \
            -H "Content-Type: application/json" \
            -H "x-mcp-user: ${MCP_USER}" \
            -d "$body" \
            < /dev/null
    fi
}

# ================================================================================
# Tool discovery
# ================================================================================

load_tool_registry() {
    local url="${API_ENDPOINT%/}/tools"
    echo "NOTE: Discovering tools from ${url} ..." >&2

    local registry
    if ! registry=$(invoke_signed_request "GET" "$url"); then
        echo "ERROR: Tool discovery request failed." >&2
        exit 1
    fi

    if [[ -z "$registry" ]] || ! echo "$registry" | jq -e . > /dev/null 2>&1; then
        echo "ERROR: Tool discovery returned invalid JSON." >&2
        exit 1
    fi

    while IFS= read -r entry; do
        local name route
        name=$(echo "$entry"  | jq -r '.name')
        route=$(echo "$entry" | jq -r '.route')
        TOOL_ROUTES["$name"]="$route"
    done < <(echo "$registry" | jq -c '.[]')

    TOOLS_JSON=$(echo "$registry" | jq -c '[.[] | {name, description, inputSchema}]')

    local count
    count=$(echo "$registry" | jq length)
    echo "NOTE: Discovered ${count} tool(s)." >&2
}

# ================================================================================
# JSON-RPC I/O helpers
# ================================================================================

send_response() {
    local id="$1" result="$2"
    jq -cn --argjson id "$id" --argjson result "$result" \
        '{"jsonrpc":"2.0","id":$id,"result":$result}'
}

send_error() {
    local id="$1" code="$2" message="$3"
    jq -cn --argjson id "$id" --argjson code "$code" --arg message "$message" \
        '{"jsonrpc":"2.0","id":$id,"error":{"code":$code,"message":$message}}'
}

# ================================================================================
# MCP method handlers
# ================================================================================

handle_initialize() {
    local id="$1"
    local result
    result=$(jq -cn '{
        "protocolVersion": "2025-11-25",
        "capabilities": {"tools": {}},
        "serverInfo": {"name": "dynamodb-mcp", "version": "1.0.0"}
    }')
    send_response "$id" "$result"
}

handle_tools_list() {
    local id="$1"
    local result
    result=$(jq -cn --argjson tools "$TOOLS_JSON" '{"tools":$tools}')
    send_response "$id" "$result"
}

handle_tools_call() {
    local id="$1" params="$2"

    local tool_name
    tool_name=$(echo "$params" | jq -r '.name // empty')

    if [[ -z "$tool_name" ]]; then
        send_error "$id" -32602 "Missing required parameter: name"
        return
    fi

    local route="${TOOL_ROUTES[$tool_name]:-}"
    if [[ -z "$route" ]]; then
        send_error "$id" -32602 "Unknown tool: $tool_name"
        return
    fi

    local url="${API_ENDPOINT%/}${route}"
    local arguments
    arguments=$(echo "$params" | jq -c '.arguments // {}')

    local text
    if ! text=$(invoke_signed_request "POST" "$url" "$arguments"); then
        send_error "$id" -32603 "Tool invocation failed: curl error"
        return
    fi

    local result
    result=$(jq -cn --arg text "$text" '{"content":[{"type":"text","text":$text}]}')
    send_response "$id" "$result"
}

# ================================================================================
# Main
# ================================================================================

echo "NOTE: DynamoDB MCP proxy started." >&2
echo "NOTE: Endpoint: ${API_ENDPOINT}  Region: ${REGION}" >&2

load_tool_registry

while IFS= read -r line; do
    line="${line//$'\r'/}"
    [[ -z "$line" ]] && continue

    if ! echo "$line" | jq -e . > /dev/null 2>&1; then
        echo "WARN: Failed to parse JSON: $line" >&2
        continue
    fi

    method=$(echo "$line" | jq -r '.method // empty')
    id_raw=$(echo "$line" | jq -c '.id // null')
    params=$(echo "$line"  | jq -c '.params // {}')

    case "$method" in
        "initialize")
            [[ "$id_raw" != "null" ]] && handle_initialize "$id_raw"
            ;;
        "notifications/initialized")
            ;;
        "tools/list")
            [[ "$id_raw" != "null" ]] && handle_tools_list "$id_raw"
            ;;
        "tools/call")
            [[ "$id_raw" != "null" ]] && handle_tools_call "$id_raw" "$params"
            ;;
        *)
            [[ "$id_raw" != "null" ]] && send_error "$id_raw" -32601 "Method not found: $method"
            ;;
    esac
done

echo "NOTE: MCP proxy exiting." >&2
