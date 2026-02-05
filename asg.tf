# ==============================================================================
# AUTO SCALING GROUP FOR ECS EC2 INSTANCES
# ==============================================================================

locals {
  asg_name = "${var.cluster_name}-ecs-${random_id.suffix.hex}"

  # Determine if we should use mixed instances policy (for Spot)
  use_mixed_instances = var.use_spot || length(var.instance_types) > 0

  # Instance types for mixed instances policy
  mixed_instance_types = length(var.instance_types) > 0 ? var.instance_types : [var.instance_type]
}

resource "aws_autoscaling_group" "ecs" {
  name                      = local.asg_name
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  protect_from_scale_in     = var.protect_from_scale_in
  max_instance_lifetime     = var.max_instance_lifetime > 0 ? var.max_instance_lifetime : null
  default_instance_warmup   = var.instance_warmup_period
  capacity_rebalance        = var.use_spot # Enable for Spot instances

  # Use launch template directly for On-Demand only
  dynamic "launch_template" {
    for_each = local.use_mixed_instances ? [] : [1]

    content {
      id      = aws_launch_template.ecs.id
      version = "$Latest"
    }
  }

  # Mixed instances policy for Spot or multiple instance types
  dynamic "mixed_instances_policy" {
    for_each = local.use_mixed_instances ? [1] : []

    content {
      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage
        spot_allocation_strategy                 = var.spot_allocation_strategy
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.ecs.id
          version            = "$Latest"
        }

        # Override instance types
        dynamic "override" {
          for_each = local.mixed_instance_types

          content {
            instance_type     = override.value
            weighted_capacity = "1"
          }
        }
      }
    }
  }

  # Instance refresh configuration
  dynamic "instance_refresh" {
    for_each = var.instance_refresh_enabled ? [1] : []

    content {
      strategy = "Rolling"

      preferences {
        min_healthy_percentage       = var.instance_refresh_min_healthy
        max_healthy_percentage       = 200
        instance_warmup              = var.instance_warmup_period
        skip_matching                = true
        auto_rollback                = true
        scale_in_protected_instances = "Ignore"
      }

      triggers = ["tag"]
    }
  }

  # Required tag for ECS managed scaling
  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "ecs:cluster"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  # Additional tags
  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      desired_capacity, # Let ECS manage this via capacity provider
    ]
  }

  depends_on = [
    aws_launch_template.ecs,
  ]
}
