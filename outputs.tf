output "table_ids" {
  description = "Map of DynamoDB table IDs"
  value       = { for k, v in aws_dynamodb_table.this : k => v.id }
}

output "table_arns" {
  description = "Map of DynamoDB table ARNs"
  value       = { for k, v in aws_dynamodb_table.this : k => v.arn }
}

output "table_names" {
  description = "Map of DynamoDB table names"
  value       = { for k, v in aws_dynamodb_table.this : k => v.name }
}

output "table_stream_arns" {
  description = "Map of stream ARNs (only tables with streams enabled)"
  value       = { for k, v in aws_dynamodb_table.this : k => v.stream_arn if v.stream_enabled }
}

output "table_stream_labels" {
  description = "Map of stream labels (only tables with streams enabled)"
  value       = { for k, v in aws_dynamodb_table.this : k => v.stream_label if v.stream_enabled }
}

output "autoscaling_read_target_ids" {
  description = "Map of read autoscaling target resource IDs"
  value       = { for k, v in aws_appautoscaling_target.read : k => v.resource_id }
}

output "autoscaling_write_target_ids" {
  description = "Map of write autoscaling target resource IDs"
  value       = { for k, v in aws_appautoscaling_target.write : k => v.resource_id }
}
