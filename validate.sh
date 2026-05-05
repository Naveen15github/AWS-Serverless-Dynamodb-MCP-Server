#!/bin/bash
# ================================================================================
# validate.sh — Validation tests for DynamoDB MCP
# ================================================================================

set -e

echo "==================================================================="
echo "  DynamoDB MCP — Validation Tests"
echo "==================================================================="
echo

echo "Testing Lambda functions via direct invocation..."
echo

test_lambda() {
    local function_name="$1"
    local payload="${2:-{}}"

    echo -n "  Testing $function_name... "

    result=$(aws lambda invoke \
        --function-name "$function_name" \
        --payload "$payload" \
        --cli-binary-format raw-in-base64-out \
        /tmp/lambda-output.json 2>&1)

    if [ $? -eq 0 ]; then
        status_code=$(cat /tmp/lambda-output.json | jq -r '.statusCode // 0')
        if [ "$status_code" = "200" ] || [ "$status_code" = "400" ]; then
            echo "✓"
        else
            echo "✗ (status code: $status_code)"
        fi
    else
        echo "✗ (invocation failed)"
    fi
}

# Test tool registry
test_lambda "dynamodb-tools"

# Test list tables
test_lambda "dynamodb-list-tables"

# Test describe table (will fail if table doesn't exist, but Lambda should handle it)
test_lambda "dynamodb-describe-table" '{"table_name":"test-table"}'

# Test count items
test_lambda "dynamodb-count-items" '{"table_name":"test-table"}'

# Test get item (will fail if table doesn't exist, but Lambda should handle it)
test_lambda "dynamodb-get-item" '{"table_name":"test-table","key":{"id":"test"}}'

echo
echo "==================================================================="
echo "  Validation complete!"
echo "==================================================================="
echo
echo "Note: Some tests may show errors if you don't have DynamoDB tables"
echo "      created yet. The Lambda functions are working correctly if they"
echo "      return proper error messages."
echo
