resource "aws_dynamodb_table" "this" {
  for_each = var.dynamodb_tables

  name         = each.value.name
  billing_mode = each.value.billing_mode
  table_class  = each.value.table_class

  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  hash_key  = each.value.hash_key
  range_key = each.value.range_key

  deletion_protection_enabled = each.value.deletion_protection_enabled

  # Table attributes (only key attributes: table keys, GSI/LSI keys)
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # TTL (Time To Live)
  dynamic "ttl" {
    for_each = each.value.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = each.value.ttl_attribute_name
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity     = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  # Local Secondary Indexes
  dynamic "local_secondary_index" {
    for_each = each.value.local_secondary_indexes
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  # Streams
  stream_enabled   = each.value.stream_enabled
  stream_view_type = each.value.stream_enabled ? each.value.stream_view_type : null

  # Global tables (replicas). Requires streams with NEW_AND_OLD_IMAGES
  dynamic "replica" {
    for_each = each.value.replicas
    content {
      region_name = replica.value.region_name
      kms_key_arn = replica.value.kms_key_arn
    }
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = each.value.point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = each.value.encryption_enabled
    kms_key_arn = each.value.kms_key_arn
  }

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.value.name
    }
  )

  # Required so Application Auto Scaling can manage provisioned capacity
  # without Terraform reverting it on the next apply. Tradeoff: manual
  # capacity edits on non-autoscaled PROVISIONED tables must be done by
  # tainting or via targeted apply. Documented in the README.
  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling — read capacity (PROVISIONED tables with autoscaling_read)
# ---------------------------------------------------------------------------

locals {
  autoscaled_read_tables = {
    for k, v in var.dynamodb_tables : k => v
    if v.billing_mode == "PROVISIONED" && v.autoscaling_read != null
  }

  autoscaled_write_tables = {
    for k, v in var.dynamodb_tables : k => v
    if v.billing_mode == "PROVISIONED" && v.autoscaling_write != null
  }
}

resource "aws_appautoscaling_target" "read" {
  for_each = local.autoscaled_read_tables

  max_capacity       = each.value.autoscaling_read.max_capacity
  min_capacity       = each.value.autoscaling_read.min_capacity
  resource_id        = "table/${aws_dynamodb_table.this[each.key].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read" {
  for_each = local.autoscaled_read_tables

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.read[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.read[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = each.value.autoscaling_read.target_value
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling — write capacity (PROVISIONED tables with autoscaling_write)
# ---------------------------------------------------------------------------

resource "aws_appautoscaling_target" "write" {
  for_each = local.autoscaled_write_tables

  max_capacity       = each.value.autoscaling_write.max_capacity
  min_capacity       = each.value.autoscaling_write.min_capacity
  resource_id        = "table/${aws_dynamodb_table.this[each.key].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write" {
  for_each = local.autoscaled_write_tables

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.write[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.write[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = each.value.autoscaling_write.target_value
  }
}
