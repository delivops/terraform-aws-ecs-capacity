# ==============================================================================
# COMPLETE EXAMPLE - Full Integration with ECS Service Module
# ==============================================================================
#
# This example demonstrates a complete setup with:
# - ECS Cluster with Service Connect
# - EC2 Capacity Provider
# - ECS Service running on EC2
# - ALB integration
#
# ==============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# NETWORKING (simplified - use your existing VPC)
# ==============================================================================

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Type = "private"
  }
}

# ==============================================================================
# SERVICE DISCOVERY NAMESPACE
# ==============================================================================

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "internal.${var.environment}"
  description = "Service discovery namespace for ${var.environment}"
  vpc         = var.vpc_id
}

# ==============================================================================
# ECS CLUSTER
# ==============================================================================

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.main.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

# ==============================================================================
# EC2 CAPACITY
# ==============================================================================

module "ecs_capacity" {
  source = "../../"

  cluster_name = aws_ecs_cluster.main.name
  vpc_id       = var.vpc_id
  subnet_ids   = data.aws_subnets.private.ids

  # Instance configuration
  instance_type    = var.instance_type
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # EBS configuration
  root_volume_size      = 50
  root_volume_encrypted = true

  # ECS Agent settings
  ecs_reserved_memory = 256
  ecs_container_instance_tags = {
    Environment = var.environment
  }

  # Security
  enable_ssm    = true
  enable_imdsv2 = true

  tags = local.tags
}

# ==============================================================================
# ATTACH CAPACITY PROVIDERS TO CLUSTER
# ==============================================================================

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
    module.ecs_capacity.capacity_provider_name,
  ]
}

# ==============================================================================
# APPLICATION LOAD BALANCER
# ==============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = local.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# ==============================================================================
# SECURITY GROUP FOR ECS TASKS
# ==============================================================================

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Allow traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# ==============================================================================
# ECS SERVICE (using terraform-aws-ecs-service module)
# ==============================================================================

# Note: Uncomment this block to use with your ECS service module
#
# module "api_service" {
#   source = "git::https://github.com/delivops/terraform-aws-ecs-service.git"
#
#   # Cluster
#   ecs_cluster_name = aws_ecs_cluster.main.name
#
#   # Service
#   ecs_service_name = "api"
#   desired_count    = 2
#
#   # EC2 Launch Type
#   ecs_launch_type            = "EC2"
#   capacity_provider_strategy = module.ecs_capacity.capacity_provider_name
#
#   # Task Definition
#   ecs_task_cpu    = 512
#   ecs_task_memory = 1024
#
#   container_name  = "api"
#   container_image = var.api_image
#   container_port  = 8080
#
#   # Networking
#   vpc_id             = var.vpc_id
#   subnet_ids         = data.aws_subnets.private.ids
#   security_group_ids = [aws_security_group.ecs_tasks.id]
#
#   # Load Balancer
#   application_load_balancer = {
#     enabled           = true
#     container_port    = 8080
#     listener_arn      = aws_lb_listener.http.arn
#     host              = "api.${var.domain}"
#     health_check_path = "/health"
#   }
#
#   # Environment
#   environment_variables = {
#     ENVIRONMENT = var.environment
#   }
#
#   tags = local.tags
# }

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "capacity_provider_name" {
  description = "EC2 capacity provider name"
  value       = module.ecs_capacity.capacity_provider_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}
