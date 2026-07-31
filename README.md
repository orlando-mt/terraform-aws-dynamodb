# terraform-aws-dynamodb

Terraform module to create multiple Amazon DynamoDB tables from a single map definition, with indexes, streams, global tables and capacity auto scaling.

## Features

- Multiple tables per module call (`for_each` map)
- Both billing modes: PAY_PER_REQUEST and PROVISIONED
- Global and Local Secondary Indexes with configurable projections
- TTL, DynamoDB Streams, point-in-time recovery, table class and deletion protection
- Global tables (cross-region replicas) with optional per-region KMS keys
- Server-side encryption (AWS-owned or customer KMS key)
- Target-tracking auto scaling for read/write capacity on PROVISIONED tables
- Extensive cross-field validations: capacity required for PROVISIONED, TTL attribute required when enabled, replicas require streams with `NEW_AND_OLD_IMAGES`, valid enums for types/projections/streams

## Usage

```hcl
module "dynamodb" {
  source = "github.com/orlando-mt/terraform-aws-dynamodb?ref=v1.0.0"

  dynamodb_tables = {
    sessions = {
      name         = "app-sessions"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "session_id"

      attributes = [
        { name = "session_id", type = "S" }
      ]

      ttl_enabled            = true
      ttl_attribute_name     = "expires_at"
      point_in_time_recovery = true
    }
  }

  common_tags = {
    Project   = "my-project"
    ManagedBy = "terraform"
  }
}
```

## Capacity management note

The table resource sets `ignore_changes` on `read_capacity` / `write_capacity` so that Application Auto Scaling can adjust provisioned capacity without Terraform reverting it on the next apply. Tradeoff: on PROVISIONED tables **without** auto scaling, capacity changes made in the module inputs will not be applied automatically — adjust them via auto scaling, or temporarily remove the ignore rule for a targeted change. `PAY_PER_REQUEST` tables are unaffected.

## Examples

- [Complete](./examples/complete)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | >= 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_dynamodb_table.this | resource |
| aws_appautoscaling_target.read | resource |
| aws_appautoscaling_policy.read | resource |
| aws_appautoscaling_target.write | resource |
| aws_appautoscaling_policy.write | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dynamodb_tables | Map of tables to create (see structure in variables.tf) | `map(object)` | `{}` | no |
| common_tags | Common tags for all resources | `map(string)` | `{}` | no |

### Per-table options

| Key | Description | Default |
|-----|-------------|---------|
| name | Table name | required |
| billing_mode | PAY_PER_REQUEST or PROVISIONED | required |
| table_class | STANDARD or STANDARD_INFREQUENT_ACCESS | `STANDARD` |
| read_capacity / write_capacity | Capacity (PROVISIONED only) | `null` |
| hash_key / range_key | Table keys | required / `null` |
| deletion_protection_enabled | Protect against deletion | `false` |
| attributes | Key attributes (name, type S/N/B) | required |
| ttl_enabled / ttl_attribute_name | TTL configuration | `false` / `null` |
| global_secondary_indexes | GSI list | `[]` |
| local_secondary_indexes | LSI list | `[]` |
| stream_enabled / stream_view_type | Streams | `false` / `NEW_AND_OLD_IMAGES` |
| point_in_time_recovery | Enable PITR | `false` |
| encryption_enabled / kms_key_arn | SSE configuration | `true` / `null` |
| replicas | Global table replicas | `[]` |
| autoscaling_read / autoscaling_write | Target-tracking config | `null` |
| tags | Per-table tags | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| table_ids | Map of table IDs |
| table_arns | Map of table ARNs |
| table_names | Map of table names |
| table_stream_arns | Map of stream ARNs (streams enabled only) |
| table_stream_labels | Map of stream labels |
| autoscaling_read_target_ids | Read autoscaling target IDs |
| autoscaling_write_target_ids | Write autoscaling target IDs |
<!-- END_TF_DOCS -->

## License

MIT. See [LICENSE](./LICENSE).
