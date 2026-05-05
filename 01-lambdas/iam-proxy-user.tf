# ================================================================================
# File: iam-proxy-user.tf
# ================================================================================
# Purpose:
#   Creates a dedicated IAM user for the MCP proxy with the minimum permission
#   needed to call the DynamoDB API Gateway endpoints. The generated access
#   key pair is stored in Secrets Manager.
# ================================================================================

resource "aws_iam_user" "mcp_proxy" {
  name = "dynamodb-mcp-proxy"
}

resource "aws_iam_user_policy" "mcp_proxy_invoke" {
  name = "dynamodb-mcp-proxy-invoke"
  user = aws_iam_user.mcp_proxy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["execute-api:Invoke"]
      Resource = "${aws_apigatewayv2_api.dynamodb_api.execution_arn}/*/*"
    }]
  })
}

resource "aws_iam_access_key" "mcp_proxy_key" {
  user = aws_iam_user.mcp_proxy.name
}

resource "aws_secretsmanager_secret" "mcp_proxy_credentials" {
  name                    = "dynamodb-mcp-proxy"
  description             = "IAM credentials for the DynamoDB MCP proxy user"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mcp_proxy_credentials" {
  secret_id = aws_secretsmanager_secret.mcp_proxy_credentials.id

  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.mcp_proxy_key.id
    secret_access_key = aws_iam_access_key.mcp_proxy_key.secret
    api_endpoint      = aws_apigatewayv2_stage.dynamodb_stage.invoke_url
    region            = data.aws_region.current.id
  })
}
