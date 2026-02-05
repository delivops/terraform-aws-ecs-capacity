# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Random suffix for unique naming when multiple capacity providers per cluster
resource "random_id" "suffix" {
  byte_length = 4
}

# Fetch the VPC for CIDR block (used in security group)
data "aws_vpc" "this" {
  id = var.vpc_id
}

# ==============================================================================
# ECS-OPTIMIZED AMI LOOKUPS
# ==============================================================================

# SSM Parameter paths for ECS-optimized AMIs
locals {
  ami_ssm_parameters = {
    standard   = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
    gpu        = "/aws/service/ecs/optimized-ami/amazon-linux-2023/gpu/recommended/image_id"
    gpu-al2    = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended/image_id"
    arm64      = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
    inferentia = "/aws/service/ecs/optimized-ami/amazon-linux-2/inf/recommended/image_id"
  }

  # If gpu_enabled is true, override ami_type to gpu
  effective_ami_type = var.gpu_enabled ? "gpu" : var.ami_type
}

# Fetch the ECS-optimized AMI from SSM Parameter Store
data "aws_ssm_parameter" "ecs_ami" {
  name = local.ami_ssm_parameters[local.effective_ami_type]
}

# Determine final AMI ID
locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ssm_parameter.ecs_ami.value
}
