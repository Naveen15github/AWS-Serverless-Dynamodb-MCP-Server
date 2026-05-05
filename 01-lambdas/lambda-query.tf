# ================================================================================
# File: lambda-query.tf
# ================================================================================
# Purpose:
#   Deploys the Query Lambda function that queries DynamoDB using partition key
#   and optional filters. Invoked via POST /dynamodb/query.
# ================================================================================

resource "aws_iam_role" "lambda_query_role" {
  name = "dynamodb-query-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_query_basic" {
  role       = aws_iam_role.lambda_query_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_query_dynamodb" {
  name = "dynamodb-query-policy"
  role = aws_iam_role.lambda_query_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Query"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_query" {
  function_name    = "dynamodb-query"
  role             = aws_iam_role.lambda_query_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.query_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
