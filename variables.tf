variable "dynamodb_tables" {
  description = "Map of DynamoDB tables to create"
  type = map(object({
    name         = string
    billing_mode = string # PAY_PER_REQUEST or PROVISIONED
    table_class  = optional(string, "STANDARD")

    read_capacity  = optional(number)
    write_capacity = optional(number)

    hash_key  = string
    range_key = optional(string)

    deletion_protection_enabled = optional(bool, false)

    attributes = list(object({
      name = string
      type = string # S, N, or B
    }))

    ttl_enabled        = optional(bool, false)
    ttl_attribute_name = optional(string)

    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = string # ALL, KEYS_ONLY, or INCLUDE
      non_key_attributes = optional(list(string))
      read_capacity      = optional(number)
      write_capacity     = optional(number)
    })), [])

    local_secondary_indexes = optional(list(object({
      name               = string
      range_key          = string
      projection_type    = string # ALL, KEYS_ONLY, or INCLUDE
      non_key_attributes = optional(list(string))
    })), [])

    stream_enabled   = optional(bool, false)
    stream_view_type = optional(string, "NEW_AND_OLD_IMAGES") # KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES

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

  default = {}

  validation {
    condition = alltrue([
      for t in var.dynamodb_tables : contains(["PAY_PER_REQUEST", "PROVISIONED"], t.billing_mode)
    ])
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }

  validation {
    condition = alltrue([
      for t in var.dynamodb_tables : contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], t.table_class)
    ])
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.dynamodb_tables : [
        for a in t.attributes : contains(["S", "N", "B"], a.type)
      ]
    ]))
    error_message = "Attribute types must be S (string), N (number) or B (binary)."
  }

  validation {
    condition = alltrue([
      for t in var.dynamodb_tables :
      t.billing_mode != "PROVISIONED" || (t.read_capacity != null && t.write_capacity != null)
    ])
    error_message = "read_capacity and write_capacity are required when billing_mode is PROVISIONED."
  }

  validation {
    condition = alltrue([
      for t in var.dynamodb_tables :
      !t.ttl_enabled || t.ttl_attribute_name != null
    ])
    error_message = "ttl_attribute_name is required when ttl_enabled is true."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.dynamodb_tables : [
        for i in concat(t.global_secondary_indexes, t.local_secondary_indexes) :
        contains(["ALL", "KEYS_ONLY", "INCLUDE"], i.projection_type)
      ]
    ]))
    error_message = "projection_type must be ALL, KEYS_ONLY or INCLUDE."
  }

  validation {
    condition = alltrue([
      for t in var.dynamodb_tables :
      !t.stream_enabled || contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], t.stream_view_type)
    ])
    error_message = "stream_view_type must be KEYS_ONLY, NEW_IMAGE, OLD_IMAGE or NEW_AND_OLD_IMAGES."
  }

  validation {
    condition = alltrue([
      for t in var.dynamodb_tables :
      length(t.replicas) == 0 || (t.stream_enabled && t.stream_view_type == "NEW_AND_OLD_IMAGES")
    ])
    error_message = "Global tables (replicas) require stream_enabled = true with stream_view_type = NEW_AND_OLD_IMAGES."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
