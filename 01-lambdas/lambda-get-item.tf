# ================================================================================
# File: lambda-get-item.tf
# ================================================================================
# Purpose:
#   Deploys the GetItem Lambda function that retrieves a single item from
#   DynamoDB by primary key. Invoked via POST /dynamodb/get-item.
# ================================================================================

resource "aws_iam_role" "lambda_get_item_role" {
  name = "dynamodb-get-item-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_get_item_basic" {
  role       = aws_iam_role.lambda_get_item_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_get_item_dynamodb" {
  name = "dynamodb-get-item-policy"
  role = aws_iam_role.lambda_get_item_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_get_item" {
  function_name    = "dynamodb-get-item"
  role             = aws_iam_role.lambda_get_item_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.get_item_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
