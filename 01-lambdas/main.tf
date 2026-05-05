# ==========================================================================================
# AWS Provider Configuration
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Defines the AWS provider and its default region for all Terraform resources
#   - Ensures all modules and resources are deployed within the same region
# ==========================================================================================

provider "aws" {
  region = "us-east-1" # Primary AWS region (N. Virginia)
}

# ------------------------------------------------------------------------------
# AWS Data Sources
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --------------------------------------------------------------------------------
# DATA: archive_file.lambdas_zip
# --------------------------------------------------------------------------------
# Description:
#   Packages all Lambda source code from the local "code" directory into a ZIP
#   archive. All handler functions live in dynamodb_ops.py so a single ZIP serves
#   every Lambda function defined in this module.
# --------------------------------------------------------------------------------
data "archive_file" "lambdas_zip" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/lambdas.zip"
}
