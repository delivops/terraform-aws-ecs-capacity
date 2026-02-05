# ==============================================================================
# IAM ROLE FOR ECS EC2 INSTANCES
# ==============================================================================

locals {
  iam_role_name = "${var.cluster_name}-ecs-instance-${random_id.suffix.hex}"
}

# Trust policy for EC2 to assume the role
data "aws_iam_policy_document" "ec2_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role for ECS EC2 instances
resource "aws_iam_role" "ecs_instance" {
  count = var.create_iam_role ? 1 : 0

  name               = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role[0].json

  tags = merge(var.tags, {
    Name = local.iam_role_name
  })
}

# Attach the required ECS policy
resource "aws_iam_role_policy_attachment" "ecs_instance" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.ecs_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach SSM policy for Session Manager access (optional)
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.create_iam_role && var.enable_ssm ? 1 : 0

  role       = aws_iam_role.ecs_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach additional IAM policies
resource "aws_iam_role_policy_attachment" "additional" {
  count = var.create_iam_role ? length(var.additional_iam_policies) : 0

  role       = aws_iam_role.ecs_instance[0].name
  policy_arn = var.additional_iam_policies[count.index]
}

# Instance profile
resource "aws_iam_instance_profile" "ecs_instance" {
  count = var.create_iam_role ? 1 : 0

  name = local.iam_role_name
  role = aws_iam_role.ecs_instance[0].name

  tags = merge(var.tags, {
    Name = local.iam_role_name
  })
}

# Determine which instance profile to use
locals {
  instance_profile_arn  = var.create_iam_role ? aws_iam_instance_profile.ecs_instance[0].arn : var.instance_profile_arn
  instance_profile_name = var.create_iam_role ? aws_iam_instance_profile.ecs_instance[0].name : null
}
