# ================================================================================
# File: lambda-tools.tf
# ================================================================================
# Purpose:
#   Deploys the tool discovery Lambda that returns the MCP tool registry.
#   Invoked via GET /tools by the proxy at startup to self-configure its
#   route map and tool schema list without any hardcoded definitions.
# ================================================================================

resource "aws_iam_role" "lambda_tools_role" {
  name = "dynamodb-tools-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_tools_basic" {
  role       = aws_iam_role.lambda_tools_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_tools" {
  function_name    = "dynamodb-tools"
  role             = aws_iam_role.lambda_tools_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.tools_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
