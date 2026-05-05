# ================================================================================
# File: api.tf
# ================================================================================
# Purpose:
#   Provides DynamoDB query endpoints for the MCP serverless API:
#     - GET  /tools                   → Tool registry for proxy self-configuration
#     - POST /dynamodb/get-item       → Get single item by key
#     - POST /dynamodb/put-item       → Add or replace an item
#     - POST /dynamodb/update-item    → Update specific attributes
#     - POST /dynamodb/delete-item    → Delete item by key
#     - POST /dynamodb/query          → Query items with partition key
#     - POST /dynamodb/scan           → Scan table with optional filters
#     - POST /dynamodb/batch-get      → Get multiple items
#     - POST /dynamodb/list-tables    → List all DynamoDB tables
#     - POST /dynamodb/describe-table → Get table metadata
#     - POST /dynamodb/count-items    → Get table item count
#
# Notes:
#   - Uses HTTP API (v2) for cost efficiency and low-latency routing
#   - All routes require AWS_IAM authorization
# ================================================================================

# --------------------------------------------------------------------------------
# RESOURCE: aws_apigatewayv2_api.dynamodb_api
# --------------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "dynamodb_api" {
  name          = "dynamodb-api"
  protocol_type = "HTTP"
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_apigatewayv2_integration — one per Lambda
# --------------------------------------------------------------------------------

resource "aws_apigatewayv2_integration" "tools_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_tools.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "get_item_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_get_item.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "put_item_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_put_item.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "update_item_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_update_item.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "delete_item_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_delete_item.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "query_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_query.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "scan_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_scan.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "batch_get_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_batch_get.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "list_tables_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_list_tables.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "describe_table_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_describe_table.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "count_items_integration" {
  api_id                 = aws_apigatewayv2_api.dynamodb_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda_count_items.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_apigatewayv2_route — one per tool endpoint
# --------------------------------------------------------------------------------

resource "aws_apigatewayv2_route" "tools_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "GET /tools"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.tools_integration.id}"
}

resource "aws_apigatewayv2_route" "get_item_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/get-item"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.get_item_integration.id}"
}

resource "aws_apigatewayv2_route" "put_item_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/put-item"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.put_item_integration.id}"
}

resource "aws_apigatewayv2_route" "update_item_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/update-item"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.update_item_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_item_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/delete-item"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.delete_item_integration.id}"
}

resource "aws_apigatewayv2_route" "query_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/query"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.query_integration.id}"
}

resource "aws_apigatewayv2_route" "scan_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/scan"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.scan_integration.id}"
}

resource "aws_apigatewayv2_route" "batch_get_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/batch-get"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.batch_get_integration.id}"
}

resource "aws_apigatewayv2_route" "list_tables_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/list-tables"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.list_tables_integration.id}"
}

resource "aws_apigatewayv2_route" "describe_table_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/describe-table"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.describe_table_integration.id}"
}

resource "aws_apigatewayv2_route" "count_items_route" {
  api_id             = aws_apigatewayv2_api.dynamodb_api.id
  route_key          = "POST /dynamodb/count-items"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.count_items_integration.id}"
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_apigatewayv2_stage.dynamodb_stage
# --------------------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "dynamodb_stage" {
  api_id      = aws_apigatewayv2_api.dynamodb_api.id
  name        = "$default"
  auto_deploy = true
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_lambda_permission — one per Lambda
# --------------------------------------------------------------------------------

resource "aws_lambda_permission" "allow_tools_invoke" {
  statement_id  = "AllowAPIGatewayInvokeTools"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_tools.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_get_item_invoke" {
  statement_id  = "AllowAPIGatewayInvokeGetItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_put_item_invoke" {
  statement_id  = "AllowAPIGatewayInvokePutItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_put_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_update_item_invoke" {
  statement_id  = "AllowAPIGatewayInvokeUpdateItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_update_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_delete_item_invoke" {
  statement_id  = "AllowAPIGatewayInvokeDeleteItem"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_delete_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_query_invoke" {
  statement_id  = "AllowAPIGatewayInvokeQuery"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_scan_invoke" {
  statement_id  = "AllowAPIGatewayInvokeScan"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_scan.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_batch_get_invoke" {
  statement_id  = "AllowAPIGatewayInvokeBatchGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_batch_get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_list_tables_invoke" {
  statement_id  = "AllowAPIGatewayInvokeListTables"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_list_tables.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_describe_table_invoke" {
  statement_id  = "AllowAPIGatewayInvokeDescribeTable"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_describe_table.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_count_items_invoke" {
  statement_id  = "AllowAPIGatewayInvokeCountItems"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_count_items.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
}
