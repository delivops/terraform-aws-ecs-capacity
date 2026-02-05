# ==============================================================================
# OUTPUTS
# ==============================================================================

# Capacity Provider
output "capacity_provider_name" {
  description = "Name of the ECS capacity provider (use in service module's capacity_provider_strategy)"
  value       = aws_ecs_capacity_provider.this.name
}

output "capacity_provider_arn" {
  description = "ARN of the ECS capacity provider"
  value       = aws_ecs_capacity_provider.this.arn
}

# Auto Scaling Group
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.arn
}

# Launch Template
output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.ecs.id
}

output "launch_template_arn" {
  description = "ARN of the Launch Template"
  value       = aws_launch_template.ecs.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.ecs.latest_version
}

# IAM
output "iam_role_arn" {
  description = "ARN of the EC2 instance IAM role (null if using existing role)"
  value       = var.create_iam_role ? aws_iam_role.ecs_instance[0].arn : null
}

output "iam_role_name" {
  description = "Name of the EC2 instance IAM role (null if using existing role)"
  value       = var.create_iam_role ? aws_iam_role.ecs_instance[0].name : null
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (null if using existing role)"
  value       = var.create_iam_role ? aws_iam_instance_profile.ecs_instance[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (null if using existing role)"
  value       = var.create_iam_role ? aws_iam_instance_profile.ecs_instance[0].name : null
}

# Security Group
output "security_group_id" {
  description = "ID of the created security group (null if not created)"
  value       = var.create_security_group ? aws_security_group.ecs_instances[0].id : null
}

output "security_group_arn" {
  description = "ARN of the created security group (null if not created)"
  value       = var.create_security_group ? aws_security_group.ecs_instances[0].arn : null
}

# AMI
output "ami_id" {
  description = "AMI ID used for EC2 instances"
  value       = local.ami_id
}
