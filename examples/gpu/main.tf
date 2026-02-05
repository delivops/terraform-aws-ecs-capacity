# ==============================================================================
# GPU EXAMPLE - GPU-enabled EC2 Capacity for ML/AI Workloads
# ==============================================================================
#
# This example demonstrates how to provision GPU-enabled EC2 instances for
# machine learning inference or training workloads on ECS.
#
# ==============================================================================

# Your existing ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "ml-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Add GPU capacity to the cluster
module "ecs_capacity_gpu" {
  source = "../../"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  # GPU instance configuration
  instance_type = "g4dn.xlarge" # 1x NVIDIA T4 GPU
  gpu_enabled   = true          # Uses GPU AMI and configures NVIDIA runtime

  # Scale from zero - instances spin up when GPU tasks are scheduled
  min_size         = 0
  max_size         = 4
  desired_capacity = 0

  # Larger root volume for ML models and container images
  root_volume_size = 100

  # Custom capacity provider name for clarity
  capacity_provider_name = "ml-gpu-nodes"

  tags = {
    Environment = "production"
    Purpose     = "ml-inference"
    GPU         = "nvidia-t4"
  }
}

# Example: ML inference service using GPU capacity
# module "ml_inference" {
#   source = "git::https://github.com/delivops/terraform-aws-ecs-service.git"
#
#   cluster_name               = aws_ecs_cluster.main.name
#   ecs_service_name           = "ml-inference"
#   ecs_launch_type            = "EC2"
#   capacity_provider_strategy = module.ecs_capacity_gpu.capacity_provider_name
#
#   # Request GPU resources
#   gpu_count = 1
#
#   # ML workloads typically need more resources
#   ecs_task_cpu    = 2048
#   ecs_task_memory = 8192
#
#   container_name  = "inference"
#   container_image = "123456789.dkr.ecr.us-east-1.amazonaws.com/ml-model:latest"
#   container_port  = 8000
#
#   # ... other configuration
# }

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "gpu_capacity_provider_name" {
  description = "GPU capacity provider name for ML services"
  value       = module.ecs_capacity_gpu.capacity_provider_name
}

output "gpu_ami_id" {
  description = "GPU-optimized AMI being used"
  value       = module.ecs_capacity_gpu.ami_id
}
