[![DelivOps banner](https://raw.githubusercontent.com/delivops/.github/main/images/banner.png?raw=true)](https://delivops.com)

# AWS ECS Capacity Terraform Module

This Terraform module provisions EC2 Auto Scaling capacity for Amazon ECS clusters with support for managed scaling, Spot instances, and GPU workloads.

## Features

- Creates ECS Capacity Provider with managed scaling and draining
- Auto Scaling Group with configurable min/max/desired capacity
- Multi-AMI support (standard, gpu, arm64, inferentia)
- Spot instance support with mixed instances policy
- GPU workload support with NVIDIA runtime auto-configuration
- ECS managed termination protection for running tasks
- IMDSv2 enforcement for secure metadata access
- SSM Session Manager integration for SSH-less access
- Configurable EBS volumes (gp3, encryption, custom IOPS)
- Instance refresh for rolling updates
- Preserves existing capacity providers (FARGATE/FARGATE_SPOT) by default

## Resources Created

- ECS Capacity Provider
- Auto Scaling Group
- Launch Template with ECS-optimized AMI
- IAM Role and Instance Profile
- Security Group (optional)

## Usage

```python

################################################################################
# AWS ECS-CAPACITY (Basic)
################################################################################

module "ecs_capacity" {
  source  = "delivops/ecs-capacity/aws"
  version = "xxx"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  instance_type    = "t3.medium"
  min_size         = 1
  max_size         = 5
  desired_capacity = 2
}
```

```python

################################################################################
# AWS ECS-CAPACITY (GPU)
################################################################################

module "ecs_capacity_gpu" {
  source  = "delivops/ecs-capacity/aws"
  version = "xxx"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  instance_type = "g4dn.xlarge"
  gpu_enabled   = true

  min_size         = 0
  max_size         = 4
  desired_capacity = 0

  root_volume_size       = 100
  capacity_provider_name = "ml-gpu-nodes"
}
```

```python

################################################################################
# AWS ECS-CAPACITY (Spot Instances)
################################################################################

module "ecs_capacity_spot" {
  source  = "delivops/ecs-capacity/aws"
  version = "xxx"

  cluster_name = var.cluster_name
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

  ecs_enable_spot_draining     = true
  instance_refresh_enabled     = true
  instance_refresh_min_healthy = 75
}
```

```python

################################################################################
# AWS ECS-CAPACITY (with ECS Service)
################################################################################

module "ecs_capacity" {
  source  = "delivops/ecs-capacity/aws"
  version = "xxx"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  instance_type    = "t3.large"
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
}

module "my_service" {
  source  = "delivops/ecs-service/aws"
  version = "xxx"

  ecs_cluster_name           = var.cluster_name
  ecs_service_name           = "my-api"
  ecs_launch_type            = "EC2"
  capacity_provider_strategy = module.ecs_capacity.capacity_provider_name
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  security_group_ids         = var.security_group_ids
}
```

## Capacity Provider Behavior

The `aws_ecs_cluster_capacity_providers` resource **replaces** all capacity providers on the cluster, not adds to them. By default, this module preserves `FARGATE` and `FARGATE_SPOT` providers. Use `existing_capacity_providers` to specify other providers to preserve, or set `preserve_existing_capacity_providers = false` if you only want EC2 capacity.

## Notes

- Default AMI type is AL2023 ECS-optimized
- Managed termination protection requires `protect_from_scale_in = true`
- GPU instances auto-configure NVIDIA runtime via user data
- Existing capacity providers (FARGATE/FARGATE_SPOT) are preserved by default
- Use `capacity_provider_strategy` in ECS service to target EC2 capacity

## License

This module is released under the MIT License.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_capacity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_iam_instance_profile.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.ecs_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.source_sg_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_ssm_parameter.ecs_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_policies"></a> [additional\_iam\_policies](#input\_additional\_iam\_policies) | Additional IAM policy ARNs to attach to the instance role | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Custom AMI ID. If not specified, latest ECS-optimized AMI will be used | `string` | `null` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | Type of ECS-optimized AMI to use: standard, gpu (AL2023), gpu-al2 (legacy), arm64, inferentia | `string` | `"standard"` | no |
| <a name="input_capacity_provider_name"></a> [capacity\_provider\_name](#input\_capacity\_provider\_name) | Name for the capacity provider. If not specified, will be generated | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the ECS cluster | `string` | n/a | yes |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Whether to create IAM role for EC2 instances | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a security group for EC2 instances | `bool` | `true` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of instances in the ASG | `number` | `1` | no |
| <a name="input_ecs_container_instance_tags"></a> [ecs\_container\_instance\_tags](#input\_ecs\_container\_instance\_tags) | Tags to apply to ECS container instances | `map(string)` | `{}` | no |
| <a name="input_ecs_enable_container_metadata"></a> [ecs\_enable\_container\_metadata](#input\_ecs\_enable\_container\_metadata) | Enable container metadata file | `bool` | `true` | no |
| <a name="input_ecs_enable_spot_draining"></a> [ecs\_enable\_spot\_draining](#input\_ecs\_enable\_spot\_draining) | Enable Spot instance draining | `bool` | `true` | no |
| <a name="input_ecs_log_level"></a> [ecs\_log\_level](#input\_ecs\_log\_level) | ECS agent log level | `string` | `"info"` | no |
| <a name="input_ecs_reserved_memory"></a> [ecs\_reserved\_memory](#input\_ecs\_reserved\_memory) | Memory to reserve for system processes (in MiB) | `number` | `256` | no |
| <a name="input_enable_imdsv2"></a> [enable\_imdsv2](#input\_enable\_imdsv2) | Require IMDSv2 for instance metadata | `bool` | `true` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | Enable SSM Session Manager access | `bool` | `true` | no |
| <a name="input_existing_capacity_providers"></a> [existing\_capacity\_providers](#input\_existing\_capacity\_providers) | List of existing capacity providers to preserve | `list(string)` | `["FARGATE", "FARGATE_SPOT"]` | no |
| <a name="input_gpu_enabled"></a> [gpu\_enabled](#input\_gpu\_enabled) | Enable GPU support (uses GPU AMI and configures NVIDIA runtime) | `bool` | `false` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | Time after instance comes into service before checking health | `number` | `300` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | Type of health check: EC2 or ELB | `string` | `"EC2"` | no |
| <a name="input_instance_profile_arn"></a> [instance\_profile\_arn](#input\_instance\_profile\_arn) | ARN of existing instance profile to use | `string` | `null` | no |
| <a name="input_instance_refresh_enabled"></a> [instance\_refresh\_enabled](#input\_instance\_refresh\_enabled) | Enable instance refresh | `bool` | `false` | no |
| <a name="input_instance_refresh_min_healthy"></a> [instance\_refresh\_min\_healthy](#input\_instance\_refresh\_min\_healthy) | Minimum healthy percentage during instance refresh | `number` | `50` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type | `string` | `"t3.medium"` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of instance types for mixed instances policy (Spot) | `list(string)` | `[]` | no |
| <a name="input_instance_warmup_period"></a> [instance\_warmup\_period](#input\_instance\_warmup\_period) | Period of time in seconds to wait for a newly launched instance to warm up | `number` | `300` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair name | `string` | `null` | no |
| <a name="input_managed_draining"></a> [managed\_draining](#input\_managed\_draining) | Enable managed draining | `bool` | `true` | no |
| <a name="input_managed_scaling_enabled"></a> [managed\_scaling\_enabled](#input\_managed\_scaling\_enabled) | Enable managed scaling for the capacity provider | `bool` | `true` | no |
| <a name="input_managed_termination_protection"></a> [managed\_termination\_protection](#input\_managed\_termination\_protection) | Enable managed termination protection | `bool` | `true` | no |
| <a name="input_max_instance_lifetime"></a> [max\_instance\_lifetime](#input\_max\_instance\_lifetime) | Maximum amount of time in seconds that an instance can be in service | `number` | `0` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances in the ASG | `number` | `10` | no |
| <a name="input_maximum_scaling_step_size"></a> [maximum\_scaling\_step\_size](#input\_maximum\_scaling\_step\_size) | Maximum step adjustment size | `number` | `10` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances in the ASG | `number` | `0` | no |
| <a name="input_minimum_scaling_step_size"></a> [minimum\_scaling\_step\_size](#input\_minimum\_scaling\_step\_size) | Minimum step adjustment size | `number` | `1` | no |
| <a name="input_on_demand_base_capacity"></a> [on\_demand\_base\_capacity](#input\_on\_demand\_base\_capacity) | Absolute minimum amount of On-Demand capacity | `number` | `0` | no |
| <a name="input_on_demand_percentage"></a> [on\_demand\_percentage](#input\_on\_demand\_percentage) | Percentage of On-Demand instances above base capacity | `number` | `0` | no |
| <a name="input_preserve_existing_capacity_providers"></a> [preserve\_existing\_capacity\_providers](#input\_preserve\_existing\_capacity\_providers) | Whether to preserve existing capacity providers on the cluster | `bool` | `true` | no |
| <a name="input_protect_from_scale_in"></a> [protect\_from\_scale\_in](#input\_protect\_from\_scale\_in) | Enable scale-in protection for ASG instances | `bool` | `true` | no |
| <a name="input_root_volume_encrypted"></a> [root\_volume\_encrypted](#input\_root\_volume\_encrypted) | Enable EBS encryption | `bool` | `true` | no |
| <a name="input_root_volume_iops"></a> [root\_volume\_iops](#input\_root\_volume\_iops) | IOPS for gp3/io volumes | `number` | `3000` | no |
| <a name="input_root_volume_kms_key_id"></a> [root\_volume\_kms\_key\_id](#input\_root\_volume\_kms\_key\_id) | KMS key ID for EBS encryption | `string` | `null` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of root EBS volume in GiB | `number` | `30` | no |
| <a name="input_root_volume_throughput"></a> [root\_volume\_throughput](#input\_root\_volume\_throughput) | Throughput for gp3 volumes in MiB/s | `number` | `125` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of root EBS volume | `string` | `"gp3"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs to attach to instances | `list(string)` | `[]` | no |
| <a name="input_security_group_source_security_group_ids"></a> [security\_group\_source\_security\_group\_ids](#input\_security\_group\_source\_security\_group\_ids) | Source security group IDs to allow ingress from | `list(string)` | `[]` | no |
| <a name="input_set_default_strategy"></a> [set\_default\_strategy](#input\_set\_default\_strategy) | Set this capacity provider as the default strategy | `bool` | `false` | no |
| <a name="input_spot_allocation_strategy"></a> [spot\_allocation\_strategy](#input\_spot\_allocation\_strategy) | Spot allocation strategy | `string` | `"price-capacity-optimized"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the ASG | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_target_capacity"></a> [target\_capacity](#input\_target\_capacity) | Target capacity percentage for managed scaling | `number` | `100` | no |
| <a name="input_use_spot"></a> [use\_spot](#input\_use\_spot) | Use Spot instances | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI ID used for EC2 instances |
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | ARN of the Auto Scaling Group |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | Name of the Auto Scaling Group |
| <a name="output_capacity_provider_arn"></a> [capacity\_provider\_arn](#output\_capacity\_provider\_arn) | ARN of the ECS capacity provider |
| <a name="output_capacity_provider_name"></a> [capacity\_provider\_name](#output\_capacity\_provider\_name) | Name of the ECS capacity provider |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the EC2 instance IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the EC2 instance IAM role |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | ARN of the instance profile |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Name of the instance profile |
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | ARN of the Launch Template |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | ID of the Launch Template |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | Latest version of the Launch Template |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the created security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the created security group |
<!-- END_TF_DOCS -->
