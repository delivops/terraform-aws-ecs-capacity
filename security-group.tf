# ==============================================================================
# SECURITY GROUP FOR ECS EC2 INSTANCES
# ==============================================================================

locals {
  security_group_name = "${var.cluster_name}-ecs-instances-${random_id.suffix.hex}"

  # Combine provided security groups with created one
  all_security_group_ids = var.create_security_group ? concat(
    var.security_group_ids,
    [aws_security_group.ecs_instances[0].id]
  ) : var.security_group_ids

  # Determine whether to use source SGs or VPC CIDR for ingress
  use_source_security_groups = length(var.security_group_source_security_group_ids) > 0
}

resource "aws_security_group" "ecs_instances" {
  count = var.create_security_group ? 1 : 0

  name        = local.security_group_name
  description = "Security group for ECS EC2 instances in cluster ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = local.security_group_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow traffic from VPC CIDR (fallback when no source security groups specified)
resource "aws_security_group_rule" "vpc_ingress" {
  count = var.create_security_group && !local.use_source_security_groups ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.ecs_instances[0].id
  description       = "Allow TCP traffic from VPC CIDR"
}

# Allow traffic from specified source security groups (more restrictive)
resource "aws_security_group_rule" "source_sg_ingress" {
  count = var.create_security_group && local.use_source_security_groups ? length(var.security_group_source_security_group_ids) : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = var.security_group_source_security_group_ids[count.index]
  security_group_id        = aws_security_group.ecs_instances[0].id
  description              = "Allow TCP traffic from source security group"
}

# Allow all outbound traffic (required for ECS agent, ECR, CloudWatch, etc.)
resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_instances[0].id
  description       = "Allow all outbound traffic"
}
