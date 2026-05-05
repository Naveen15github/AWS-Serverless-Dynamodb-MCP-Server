# ================================================================================
# File: lambda-scan.tf
# ================================================================================
# Purpose:
#   Deploys the Scan Lambda function that scans DynamoDB table with optional
#   filters. Invoked via POST /dynamodb/scan.
# ================================================================================

resource "aws_iam_role" "lambda_scan_role" {
  name = "dynamodb-scan-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_scan_basic" {
  role       = aws_iam_role.lambda_scan_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_scan_dynamodb" {
  name = "dynamodb-scan-policy"
  role = aws_iam_role.lambda_scan_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Scan"]
      Resource = ["*"]
    }]
  })
}

resource "aws_lambda_function" "lambda_scan" {
  function_name    = "dynamodb-scan"
  role             = aws_iam_role.lambda_scan_role.arn
  runtime          = "python3.13"
  handler          = "dynamodb_ops.scan_handler"
  filename         = data.archive_file.lambdas_zip.output_path
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
  timeout          = 15
}
