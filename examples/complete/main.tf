provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Customer managed key for table encryption
resource "aws_kms_key" "dynamodb" {
  description             = "Encryption key for the example DynamoDB tables"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/example-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

locals {
  # Encrypt every table with the customer managed key unless the table
  # definition already specifies one
  tables = {
    for k, v in var.dynamodb_tables : k => merge(v, {
      kms_key_arn = coalesce(v.kms_key_arn, aws_kms_key.dynamodb.arn)
    })
  }
}

module "dynamodb" {
  source = "../../"

  dynamodb_tables = local.tables
  common_tags     = var.common_tags
}
