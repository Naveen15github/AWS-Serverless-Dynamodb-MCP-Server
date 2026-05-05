# ================================================================================
# File: lambda-list-tables.tf
# ================================================================================
# Purpose:
#   Deploys the ListTables Lambda function that lists all DynamoDB tables in
#   the AWS account/region. Invoked via POST /dynamodb/list-tables.
# ================================================================================

resource "aws_iam_role" "lambda_list_tables_role" {
  name = "dynamodb-list-tables-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_list_tables_basic" {
  role       = aws_iam_role.lambda_list_tables_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_list_tables_dynamodb" {
  name = "dynamodb-list-tables-policy"
  role = aws_iam_role.lambda_list_tables_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:ListTables"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_list_tables" {
  function_name    = "dynamodb-list-tables"
  role             = aws_iam_role.lambda_list_tables_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.list_tables_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
