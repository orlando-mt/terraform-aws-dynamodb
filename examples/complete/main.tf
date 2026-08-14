provider "aws" {
  region = var.region
}

module "dynamodb" {
  source = "../../"

  dynamodb_tables = var.dynamodb_tables
  common_tags     = var.common_tags
}
