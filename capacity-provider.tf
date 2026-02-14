# ==============================================================================
# ECS CAPACITY PROVIDER
# ==============================================================================

locals {
  capacity_provider_name = var.capacity_provider_name != null ? var.capacity_provider_name : "${var.cluster_name}-ec2-${local.resource_suffix}"
}

resource "aws_ecs_capacity_provider" "this" {
  name = local.capacity_provider_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = var.managed_termination_protection ? "ENABLED" : "DISABLED"
    managed_draining               = var.managed_draining ? "ENABLED" : "DISABLED"

    dynamic "managed_scaling" {
      for_each = var.managed_scaling_enabled ? [1] : []

      content {
        status                    = "ENABLED"
        target_capacity           = var.target_capacity
        minimum_scaling_step_size = var.minimum_scaling_step_size
        maximum_scaling_step_size = var.maximum_scaling_step_size
        instance_warmup_period    = var.instance_warmup_period
      }
    }
  }

  tags = merge(var.tags, {
    Name          = local.capacity_provider_name
    "ecs:cluster" = var.cluster_name
  })

  lifecycle {
    precondition {
      condition     = !(var.managed_termination_protection && !var.managed_scaling_enabled)
      error_message = "managed_termination_protection requires managed_scaling_enabled = true. Without managed scaling, ECS cannot manage per-instance scale-in protection, causing all instances to remain protected."
    }
  }

  depends_on = [
    aws_autoscaling_group.ecs,
  ]
}
