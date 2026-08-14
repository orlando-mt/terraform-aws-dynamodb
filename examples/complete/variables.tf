variable "region" {
  description = "AWS region"
  type        = string
}

variable "dynamodb_tables" {
  description = "Tables to create"
  type = map(object({
    name                        = string
    billing_mode                = string
    table_class                 = optional(string, "STANDARD")
    read_capacity               = optional(number)
    write_capacity              = optional(number)
    hash_key                    = string
    range_key                   = optional(string)
    deletion_protection_enabled = optional(bool, false)
    attributes = list(object({
      name = string
      type = string
    }))
    ttl_enabled        = optional(bool, false)
    ttl_attribute_name = optional(string)
    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = string
      non_key_attributes = optional(list(string))
      read_capacity      = optional(number)
      write_capacity     = optional(number)
    })), [])
    local_secondary_indexes = optional(list(object({
      name               = string
      range_key          = string
      projection_type    = string
      non_key_attributes = optional(list(string))
    })), [])
    stream_enabled         = optional(bool, false)
    stream_view_type       = optional(string, "NEW_AND_OLD_IMAGES")
    point_in_time_recovery = optional(bool, false)
    encryption_enabled     = optional(bool, true)
    kms_key_arn            = optional(string)
    replicas = optional(list(object({
      region_name = string
      kms_key_arn = optional(string)
    })), [])
    autoscaling_read = optional(object({
      max_capacity = number
      min_capacity = number
      target_value = number
    }))
    autoscaling_write = optional(object({
      max_capacity = number
      min_capacity = number
      target_value = number
    }))
    tags = optional(map(string), {})
  }))
}

variable "common_tags" {
  description = "Tags applied to all tables"
  type        = map(string)
  default     = {}
}
