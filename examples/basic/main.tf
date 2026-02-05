# ==============================================================================
# BASIC EXAMPLE - Minimal EC2 Capacity for ECS
# ==============================================================================
#
# This example demonstrates the minimal configuration needed to add EC2 capacity
# to an existing ECS cluster.
#
# ==============================================================================

# Your existing ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "my-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Add EC2 capacity to the cluster
module "ecs_capacity" {
  source = "../../"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  # Instance configuration
  instance_type    = "t3.medium"
  min_size         = 1
  max_size         = 5
  desired_capacity = 2

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

# ==============================================================================
# ATTACH CAPACITY PROVIDERS TO CLUSTER
# ==============================================================================
# This is managed outside the module so you can safely combine multiple
# capacity providers (e.g., Spot + On-Demand, or multiple EC2 pools).

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
    module.ecs_capacity.capacity_provider_name,
  ]
}

# Use with the ECS service module
# module "my_service" {
#   source = "git::https://github.com/delivops/terraform-aws-ecs-service.git"
#
#   cluster_name               = aws_ecs_cluster.main.name
#   ecs_service_name           = "my-api"
#   ecs_launch_type            = "EC2"
#   capacity_provider_strategy = module.ecs_capacity.capacity_provider_name
#
#   # ... other configuration
# }

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "capacity_provider_name" {
  description = "Use this in your ECS service module"
  value       = module.ecs_capacity.capacity_provider_name
}
