# Complete example

Creates two tables showing both billing modes:

- `sessions`: PAY_PER_REQUEST with TTL and point-in-time recovery
- `orders`: PROVISIONED with a GSI, streams, deletion protection and
  read/write target-tracking auto scaling

Values live in [`terraform.tfvars`](./terraform.tfvars).

## Usage

```bash
terraform init
terraform plan
terraform apply
```
