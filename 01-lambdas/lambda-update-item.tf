# ================================================================================
# File: lambda-update-item.tf
# ================================================================================
# Purpose:
#   Deploys the UpdateItem Lambda function that updates specific attributes of
#   an item in DynamoDB. Invoked via POST /dynamodb/update-item.
# ================================================================================

resource "aws_iam_role" "lambda_update_item_role" {
  name = "dynamodb-update-item-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_update_item_basic" {
  role       = aws_iam_role.lambda_update_item_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_update_item_dynamodb" {
  name = "dynamodb-update-item-policy"
  role = aws_iam_role.lambda_update_item_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:UpdateItem"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_update_item" {
  function_name    = "dynamodb-update-item"
  role             = aws_iam_role.lambda_update_item_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.update_item_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
