# ==============================================================================
# SPOT EXAMPLE - Cost-Optimized EC2 Capacity with Spot Instances
# ==============================================================================
#
# This example demonstrates how to use Spot instances to reduce costs while
# maintaining availability through mixed instances policy and capacity rebalancing.
#
# ==============================================================================

# Your existing ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "cost-optimized-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Add Spot capacity to the cluster
module "ecs_capacity_spot" {
  source = "../../"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  # Enable Spot instances
  use_spot = true

  # Multiple instance types for better Spot availability
  instance_types = [
    "t3.large",
    "t3a.large",
    "m5.large",
    "m5a.large",
  ]

  # Keep at least 1 On-Demand instance for baseline stability
  on_demand_base_capacity = 1
  on_demand_percentage    = 0 # 100% Spot above base capacity

  # Spot allocation strategy
  # - "price-capacity-optimized": Best balance of price and capacity (recommended)
  # - "capacity-optimized": Prioritize capacity availability
  # - "lowest-price": Prioritize lowest price (higher interruption risk)
  spot_allocation_strategy = "price-capacity-optimized"

  # Scaling configuration
  min_size         = 1
  max_size         = 20
  desired_capacity = 3

  # Enable Spot instance draining for graceful interruption handling
  ecs_enable_spot_draining = true

  # Enable instance refresh to rotate instances periodically
  instance_refresh_enabled     = true
  instance_refresh_min_healthy = 75

  tags = {
    Environment = "staging"
    CostCenter  = "engineering"
    SpotEnabled = "true"
  }
}

# For comparison: On-Demand capacity provider for critical services
module "ecs_capacity_ondemand" {
  source = "../../"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  # On-Demand only (default)
  instance_type    = "t3.large"
  min_size         = 1
  max_size         = 5
  desired_capacity = 1

  # Different capacity provider name
  capacity_provider_name = "critical-ondemand"

  tags = {
    Environment = "staging"
    Purpose     = "critical-services"
  }
}

# ==============================================================================
# USAGE WITH SERVICES
# ==============================================================================
#
# Non-critical services can use Spot:
# module "batch_processor" {
#   source = "git::https://github.com/delivops/terraform-aws-ecs-service.git"
#
#   cluster_name               = aws_ecs_cluster.main.name
#   ecs_service_name           = "batch-processor"
#   ecs_launch_type            = "EC2"
#   capacity_provider_strategy = module.ecs_capacity_spot.capacity_provider_name
#   # ...
# }
#
# Critical services use On-Demand:
# module "payment_api" {
#   source = "git::https://github.com/delivops/terraform-aws-ecs-service.git"
#
#   cluster_name               = aws_ecs_cluster.main.name
#   ecs_service_name           = "payment-api"
#   ecs_launch_type            = "EC2"
#   capacity_provider_strategy = module.ecs_capacity_ondemand.capacity_provider_name
#   # ...
# }

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "spot_capacity_provider_name" {
  description = "Spot capacity provider for cost-sensitive workloads"
  value       = module.ecs_capacity_spot.capacity_provider_name
}

output "ondemand_capacity_provider_name" {
  description = "On-Demand capacity provider for critical workloads"
  value       = module.ecs_capacity_ondemand.capacity_provider_name
}
