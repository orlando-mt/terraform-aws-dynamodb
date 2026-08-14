region = "us-east-1"

dynamodb_tables = {
  # Serverless table with TTL and point-in-time recovery
  sessions = {
    name         = "example-sessions"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "session_id"

    attributes = [
      { name = "session_id", type = "S" }
    ]

    ttl_enabled            = true
    ttl_attribute_name     = "expires_at"
    point_in_time_recovery = true
  }

  # Provisioned table with a GSI, streams and autoscaling
  orders = {
    name           = "example-orders"
    billing_mode   = "PROVISIONED"
    read_capacity  = 5
    write_capacity = 5
    hash_key       = "order_id"
    range_key      = "created_at"

    deletion_protection_enabled = true
    point_in_time_recovery      = true

    attributes = [
      { name = "order_id", type = "S" },
      { name = "created_at", type = "S" },
      { name = "customer_id", type = "S" }
    ]

    global_secondary_indexes = [
      {
        name            = "by-customer"
        hash_key        = "customer_id"
        projection_type = "ALL"
        read_capacity   = 5
        write_capacity  = 5
      }
    ]

    stream_enabled   = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    autoscaling_read = {
      min_capacity = 5
      max_capacity = 50
      target_value = 70
    }

    autoscaling_write = {
      min_capacity = 5
      max_capacity = 50
      target_value = 70
    }
  }
}

common_tags = {
  Project   = "example"
  ManagedBy = "terraform"
}
