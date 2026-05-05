# ================================================================================
# File: lambda-count-items.tf
# ================================================================================
# Purpose:
#   Deploys the CountItems Lambda function that gets the total item count in a
#   DynamoDB table. Invoked via POST /dynamodb/count-items.
# ================================================================================

resource "aws_iam_role" "lambda_count_items_role" {
  name = "dynamodb-count-items-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_count_items_basic" {
  role       = aws_iam_role.lambda_count_items_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_count_items_dynamodb" {
  name = "dynamodb-count-items-policy"
  role = aws_iam_role.lambda_count_items_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:DescribeTable"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_count_items" {
  function_name    = "dynamodb-count-items"
  role             = aws_iam_role.lambda_count_items_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.count_items_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
