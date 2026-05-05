# ================================================================================
# File: lambda-describe-table.tf
# ================================================================================
# Purpose:
#   Deploys the DescribeTable Lambda function that gets detailed metadata about
#   a DynamoDB table. Invoked via POST /dynamodb/describe-table.
# ================================================================================

resource "aws_iam_role" "lambda_describe_table_role" {
  name = "dynamodb-describe-table-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_describe_table_basic" {
  role       = aws_iam_role.lambda_describe_table_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_describe_table_dynamodb" {
  name = "dynamodb-describe-table-policy"
  role = aws_iam_role.lambda_describe_table_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:DescribeTable"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_describe_table" {
  function_name    = "dynamodb-describe-table"
  role             = aws_iam_role.lambda_describe_table_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.describe_table_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
