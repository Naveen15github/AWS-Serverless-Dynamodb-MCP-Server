# ================================================================================
# File: sample-table.tf
# ================================================================================
# Purpose:
#   OPTIONAL - Creates a sample DynamoDB table with test data for demonstration.
#
#   To use this sample table:
#     1. Leave this file as-is and run ./apply.sh
#
#   To skip this sample table:
#     1. Rename this file (e.g., sample-table.tf.disabled)
#     OR
#     2. Delete this file entirely
#     OR
#     3. Comment out all resources below
# ================================================================================

# --------------------------------------------------------------------------------
# RESOURCE: aws_dynamodb_table.users_sample
# --------------------------------------------------------------------------------
# Description:
#   Sample Users table for testing the DynamoDB MCP tools.
#   - Primary key: userId (String)
#   - Pay-per-request billing mode (no fixed costs)
# --------------------------------------------------------------------------------
resource "aws_dynamodb_table" "users_sample" {
  name           = "Users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  # Global Secondary Index for querying by email
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Users Sample Table"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Purpose     = "DynamoDB MCP Demo"
  }
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_dynamodb_table_item — Sample user records
# --------------------------------------------------------------------------------
# Description:
#   Pre-populates the Users table with sample data for testing.
# --------------------------------------------------------------------------------

resource "aws_dynamodb_table_item" "user_1" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user001" }
    name   = { S = "Alice Johnson" }
    email  = { S = "alice.johnson@example.com" }
    age    = { N = "28" }
    role   = { S = "Software Engineer" }
    department = { S = "Engineering" }
    active = { BOOL = true }
    joinDate = { S = "2022-03-15" }
  })
}

resource "aws_dynamodb_table_item" "user_2" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user002" }
    name   = { S = "Bob Smith" }
    email  = { S = "bob.smith@example.com" }
    age    = { N = "35" }
    role   = { S = "Product Manager" }
    department = { S = "Product" }
    active = { BOOL = true }
    joinDate = { S = "2021-07-22" }
  })
}

resource "aws_dynamodb_table_item" "user_3" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user003" }
    name   = { S = "Carol Davis" }
    email  = { S = "carol.davis@example.com" }
    age    = { N = "42" }
    role   = { S = "Engineering Manager" }
    department = { S = "Engineering" }
    active = { BOOL = true }
    joinDate = { S = "2020-01-10" }
  })
}

resource "aws_dynamodb_table_item" "user_4" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user004" }
    name   = { S = "David Lee" }
    email  = { S = "david.lee@example.com" }
    age    = { N = "31" }
    role   = { S = "DevOps Engineer" }
    department = { S = "Engineering" }
    active = { BOOL = true }
    joinDate = { S = "2021-11-05" }
  })
}

resource "aws_dynamodb_table_item" "user_5" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user005" }
    name   = { S = "Emma Wilson" }
    email  = { S = "emma.wilson@example.com" }
    age    = { N = "26" }
    role   = { S = "UI/UX Designer" }
    department = { S = "Design" }
    active = { BOOL = false }
    joinDate = { S = "2023-02-14" }
    exitDate = { S = "2024-01-20" }
  })
}

resource "aws_dynamodb_table_item" "user_6" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user006" }
    name   = { S = "Frank Martinez" }
    email  = { S = "frank.martinez@example.com" }
    age    = { N = "39" }
    role   = { S = "Data Scientist" }
    department = { S = "Data" }
    active = { BOOL = true }
    joinDate = { S = "2020-09-18" }
  })
}

resource "aws_dynamodb_table_item" "user_7" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user007" }
    name   = { S = "Grace Chen" }
    email  = { S = "grace.chen@example.com" }
    age    = { N = "29" }
    role   = { S = "Frontend Developer" }
    department = { S = "Engineering" }
    active = { BOOL = true }
    joinDate = { S = "2022-06-01" }
  })
}

resource "aws_dynamodb_table_item" "user_8" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user008" }
    name   = { S = "Henry Taylor" }
    email  = { S = "henry.taylor@example.com" }
    age    = { N = "45" }
    role   = { S = "VP of Engineering" }
    department = { S = "Engineering" }
    active = { BOOL = true }
    joinDate = { S = "2019-04-12" }
  })
}

resource "aws_dynamodb_table_item" "user_9" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user009" }
    name   = { S = "Iris Anderson" }
    email  = { S = "iris.anderson@example.com" }
    age    = { N = "33" }
    role   = { S = "Security Engineer" }
    department = { S = "Security" }
    active = { BOOL = true }
    joinDate = { S = "2021-03-25" }
  })
}

resource "aws_dynamodb_table_item" "user_10" {
  table_name = aws_dynamodb_table.users_sample.name
  hash_key   = aws_dynamodb_table.users_sample.hash_key

  item = jsonencode({
    userId = { S = "user010" }
    name   = { S = "Jack Robinson" }
    email  = { S = "jack.robinson@example.com" }
    age    = { N = "27" }
    role   = { S = "Backend Developer" }
    department = { S = "Engineering" }
    active = { BOOL = true }
    joinDate = { S = "2023-08-10" }
  })
}

# --------------------------------------------------------------------------------
# OUTPUT: Sample table information
# --------------------------------------------------------------------------------
output "sample_table_name" {
  description = "Name of the sample Users table"
  value       = aws_dynamodb_table.users_sample.name
}

output "sample_table_arn" {
  description = "ARN of the sample Users table"
  value       = aws_dynamodb_table.users_sample.arn
}

output "sample_data_count" {
  description = "Number of sample users created"
  value       = 10
}
