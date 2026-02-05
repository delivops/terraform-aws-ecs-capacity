# terraform-aws-ecs-capacity

Terraform module to provision EC2 Auto Scaling capacity for Amazon ECS clusters.

## Overview

This module creates the infrastructure needed to run ECS services on EC2 instances:

- **Launch Template** — EC2 instance configuration with ECS-optimized AMI
- **Auto Scaling Group** — Managed EC2 fleet with scaling policies
- **Capacity Provider** — Links ASG to ECS with managed scaling
- **IAM Resources** — Instance role and profile for ECS agent
- **Security Group** — (Optional) VPC CIDR ingress for service-to-service communication

> ⚠️ **Important**: The `aws_ecs_cluster_capacity_providers` resource **replaces** all capacity providers on the cluster, not adds to them. By default, this module preserves `FARGATE` and `FARGATE_SPOT` providers. Use `existing_capacity_providers` to specify other providers to preserve, or set `preserve_existing_capacity_providers = false` if you only want EC2 capacity.

## Usage

### Basic Example

```hcl
# Your existing ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "production"
}

# Add EC2 capacity
module "ecs_capacity" {
  source = "path/to/modules/ecs-capacity"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  instance_type    = "t3.large"
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
}

# Use with ECS service module
module "my_service" {
  source = "git::https://github.com/delivops/terraform-aws-ecs-service.git"

  ecs_cluster_name           = aws_ecs_cluster.main.name
  ecs_service_name           = "my-api"
  ecs_launch_type            = "EC2"
  capacity_provider_strategy = module.ecs_capacity.capacity_provider_name

  # ... other configuration
}
```

### GPU Example

```hcl
module "ecs_capacity_gpu" {
  source = "path/to/modules/ecs-capacity"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  instance_type = "g4dn.xlarge"
  gpu_enabled   = true

  min_size         = 0
  max_size         = 4
  desired_capacity = 0  # Scale from zero

  capacity_provider_name = "gpu-nodes"
}
```

### Spot Instances

```hcl
module "ecs_capacity_spot" {
  source = "path/to/modules/ecs-capacity"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  use_spot = true
  instance_types = [
    "t3.large",
    "t3a.large",
    "m5.large",
    "m5a.large",
  ]

  on_demand_base_capacity  = 1
  on_demand_percentage     = 0
  spot_allocation_strategy = "price-capacity-optimized"

  min_size         = 1
  max_size         = 20
  desired_capacity = 3
}
```

### Multiple Capacity Providers

You can create multiple capacity providers for different workload types:

```hcl
# Standard compute
module "ecs_capacity_standard" {
  source = "path/to/modules/ecs-capacity"

  cluster_name           = aws_ecs_cluster.main.name
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  instance_type          = "t3.large"
  capacity_provider_name = "standard"
}

# GPU compute
module "ecs_capacity_gpu" {
  source = "path/to/modules/ecs-capacity"

  cluster_name           = aws_ecs_cluster.main.name
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  instance_type          = "g4dn.xlarge"
  gpu_enabled            = true
  capacity_provider_name = "gpu"
}

# Spot for batch jobs
module "ecs_capacity_spot" {
  source = "path/to/modules/ecs-capacity"

  cluster_name           = aws_ecs_cluster.main.name
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  use_spot               = true
  instance_types         = ["t3.large", "t3a.large"]
  capacity_provider_name = "spot"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| random | >= 3.0 |

## Inputs

### Required

| Name | Description | Type |
|------|-------------|------|
| `cluster_name` | Name of the existing ECS cluster | `string` |
| `vpc_id` | VPC ID for security group creation | `string` |
| `subnet_ids` | List of subnet IDs for ASG | `list(string)` |

### Instance Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `instance_type` | EC2 instance type | `string` | `"t3.medium"` |
| `instance_types` | Instance types for mixed instances (Spot) | `list(string)` | `[]` |
| `use_spot` | Use Spot instances | `bool` | `false` |
| `spot_allocation_strategy` | Spot allocation strategy | `string` | `"price-capacity-optimized"` |
| `on_demand_base_capacity` | Minimum On-Demand instances | `number` | `0` |
| `on_demand_percentage` | On-Demand percentage above base | `number` | `0` |
| `key_name` | SSH key pair name | `string` | `null` |

### AMI Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ami_id` | Custom AMI ID (overrides SSM lookup) | `string` | `null` |
| `ami_type` | AMI type: `standard`, `gpu` (AL2023), `gpu-al2` (legacy), `arm64`, `inferentia` | `string` | `"standard"` |
| `gpu_enabled` | Enable GPU support | `bool` | `false` |

### Auto Scaling Group

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `min_size` | Minimum instances | `number` | `0` |
| `max_size` | Maximum instances | `number` | `10` |
| `desired_capacity` | Initial desired capacity | `number` | `1` |
| `health_check_type` | Health check type: `EC2` or `ELB` | `string` | `"EC2"` |
| `health_check_grace_period` | Health check grace period (seconds) | `number` | `300` |
| `protect_from_scale_in` | Enable scale-in protection | `bool` | `true` |
| `max_instance_lifetime` | Max instance lifetime (seconds, 0=disabled) | `number` | `0` |
| `instance_refresh_enabled` | Enable instance refresh | `bool` | `false` |
| `instance_refresh_min_healthy` | Min healthy % during refresh | `number` | `50` |

### EBS Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `root_volume_size` | Root volume size (GiB) | `number` | `30` |
| `root_volume_type` | Volume type: `gp3`, `gp2`, `io1`, `io2` | `string` | `"gp3"` |
| `root_volume_iops` | IOPS for gp3/io volumes | `number` | `3000` |
| `root_volume_throughput` | Throughput for gp3 (MiB/s) | `number` | `125` |
| `root_volume_encrypted` | Enable encryption | `bool` | `true` |
| `root_volume_kms_key_id` | KMS key for encryption | `string` | `null` |

### Capacity Provider

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `capacity_provider_name` | Custom name | `string` | `null` |
| `managed_scaling_enabled` | Enable managed scaling | `bool` | `true` |
| `target_capacity` | Target utilization % (1-100) | `number` | `100` |
| `minimum_scaling_step_size` | Min scaling step | `number` | `1` |
| `maximum_scaling_step_size` | Max scaling step | `number` | `10` |
| `instance_warmup_period` | Warmup period (seconds) | `number` | `300` |
| `managed_termination_protection` | Prevent termination with tasks | `bool` | `true` |
| `managed_draining` | Enable task draining | `bool` | `true` |
| `set_default_strategy` | Set as cluster default | `bool` | `false` |
| `existing_capacity_providers` | Capacity providers to preserve | `list(string)` | `["FARGATE", "FARGATE_SPOT"]` |
| `preserve_existing_capacity_providers` | Preserve existing providers | `bool` | `true` |

### ECS Agent

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ecs_reserved_memory` | Reserved memory (MiB) | `number` | `256` |
| `ecs_enable_spot_draining` | Handle Spot interruptions | `bool` | `true` |
| `ecs_container_instance_tags` | Container instance tags | `map(string)` | `{}` |
| `ecs_log_level` | Agent log level | `string` | `"info"` |
| `ecs_enable_container_metadata` | Enable metadata file | `bool` | `true` |

### Security

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `security_group_ids` | Existing security groups | `list(string)` | `[]` |
| `create_security_group` | Create security group | `bool` | `true` |
| `security_group_source_security_group_ids` | Source SGs to allow ingress from (instead of VPC CIDR) | `list(string)` | `[]` |
| `enable_imdsv2` | Require IMDSv2 | `bool` | `true` |
| `enable_ssm` | Enable SSM Session Manager | `bool` | `true` |

### IAM

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_iam_role` | Create IAM role | `bool` | `true` |
| `instance_profile_arn` | Existing instance profile ARN (required if create_iam_role = false) | `string` | `null` |
| `additional_iam_policies` | Additional policy ARNs | `list(string)` | `[]` |

### Tags

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tags` | Tags for all resources | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `capacity_provider_name` | Capacity provider name (for service module) |
| `capacity_provider_arn` | Capacity provider ARN |
| `autoscaling_group_name` | ASG name |
| `autoscaling_group_arn` | ASG ARN |
| `launch_template_id` | Launch template ID |
| `launch_template_arn` | Launch template ARN |
| `launch_template_latest_version` | Latest launch template version |
| `iam_role_arn` | Instance IAM role ARN |
| `iam_role_name` | Instance IAM role name |
| `instance_profile_arn` | Instance profile ARN |
| `instance_profile_name` | Instance profile name |
| `security_group_id` | Created security group ID |
| `security_group_arn` | Created security group ARN |
| `ami_id` | AMI ID used |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ECS Cluster                               │
│                   (created separately)                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ECS Capacity Provider                           │
│              (aws_ecs_capacity_provider)                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Managed Scaling: target_capacity, step sizes            │   │
│  │  Termination Protection: ENABLED                         │   │
│  │  Managed Draining: ENABLED                               │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Auto Scaling Group                            │
│                  (aws_autoscaling_group)                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  min_size / max_size / desired_capacity                  │   │
│  │  Mixed Instances Policy (for Spot)                       │   │
│  │  Tag: AmazonECSManaged = true                            │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Launch Template                              │
│                  (aws_launch_template)                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  ECS-Optimized AMI (standard, gpu, arm64, inferentia)    │   │
│  │  Instance Type / EBS / Security Groups                   │   │
│  │  IAM Instance Profile                                    │   │
│  │  User Data (ECS Agent configuration)                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Examples

- [Basic](examples/basic) — Minimal EC2 capacity
- [GPU](examples/gpu) — GPU instances for ML workloads
- [Spot](examples/spot) — Cost-optimized with Spot instances
- [Complete](examples/complete) — Full integration with ECS service

## License

MIT
