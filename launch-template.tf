# ==============================================================================
# LAUNCH TEMPLATE FOR ECS EC2 INSTANCES
# ==============================================================================

locals {
  launch_template_name = "${var.cluster_name}-ecs-${local.resource_suffix}"

  # Prepare container instance tags as JSON
  container_instance_tags_json = length(var.ecs_container_instance_tags) > 0 ? jsonencode(var.ecs_container_instance_tags) : "{}"

  # User data script
  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tpl", {
    cluster_name                  = var.cluster_name
    ecs_reserved_memory           = var.ecs_reserved_memory
    ecs_enable_spot_draining      = var.ecs_enable_spot_draining ? "true" : "false"
    ecs_enable_container_metadata = var.ecs_enable_container_metadata ? "true" : "false"
    ecs_log_level                 = var.ecs_log_level
    ecs_container_instance_tags   = local.container_instance_tags_json
    gpu_enabled                   = var.gpu_enabled
    additional_user_data          = var.additional_user_data
  }))
}

resource "aws_launch_template" "ecs" {
  name                   = local.launch_template_name
  description            = "Launch template for ECS EC2 instances in cluster ${var.cluster_name}"
  image_id               = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = local.user_data
  update_default_version = true
  ebs_optimized          = true

  # IAM Instance Profile
  iam_instance_profile {
    arn = local.instance_profile_arn
  }

  # Network configuration
  vpc_security_group_ids = local.all_security_group_ids

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enable_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 2 # Required for containers to access IMDS
    instance_metadata_tags      = "enabled"
  }

  # Root volume
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      iops                  = var.root_volume_type == "gp3" || startswith(var.root_volume_type, "io") ? var.root_volume_iops : null
      throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
      encrypted             = var.root_volume_encrypted
      kms_key_id            = var.root_volume_kms_key_id
      delete_on_termination = true
    }
  }

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  # Tags for instances and volumes
  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name               = "${var.cluster_name}-ecs-instance"
      "ecs:cluster"      = var.cluster_name
      "AmazonECSManaged" = "true"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.tags, {
      Name          = "${var.cluster_name}-ecs-volume"
      "ecs:cluster" = var.cluster_name
    })
  }

  tags = merge(var.tags, {
    Name = local.launch_template_name
  })

  lifecycle {
    create_before_destroy = true
  }
}
