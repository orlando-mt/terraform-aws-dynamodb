output "table_arns" {
  description = "ARNs of the created tables"
  value       = module.dynamodb.table_arns
}

output "stream_arns" {
  description = "Stream ARNs (for Lambda/ESM consumers)"
  value       = module.dynamodb.table_stream_arns
}
