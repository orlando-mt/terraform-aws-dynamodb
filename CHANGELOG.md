# Changelog

## [1.0.0] - 2026-07-30

### Added
- Initial release: multiple DynamoDB tables from a single map definition
- GSI/LSI, TTL, streams, global tables (replicas), PITR, SSE with
  optional KMS key, table class and deletion protection
- Target-tracking auto scaling for read/write capacity on PROVISIONED tables
- Extensive cross-field input validations (capacity vs billing mode,
  TTL attribute, stream requirements for replicas, valid enums)
