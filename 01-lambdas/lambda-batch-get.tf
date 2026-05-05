# ================================================================================
# File: lambda-batch-get.tf
# ================================================================================
# Purpose:
#   Deploys the BatchGetItem Lambda function that retrieves multiple items from
#   DynamoDB in a single request. Invoked via POST /dynamodb/batch-get.
# ================================================================================

resource "aws_iam_role" "lambda_batch_get_role" {
  name = "dynamodb-batch-get-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_batch_get_basic" {
  role       = aws_iam_role.lambda_batch_get_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_batch_get_dynamodb" {
  name = "dynamodb-batch-get-policy"
  role = aws_iam_role.lambda_batch_get_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:BatchGetItem"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_batch_get" {
  function_name    = "dynamodb-batch-get"
  role             = aws_iam_role.lambda_batch_get_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.batch_get_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
