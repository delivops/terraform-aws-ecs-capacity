# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "cluster_name" {
  description = "Name of the existing ECS cluster to attach capacity to"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group creation"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ASG instance placement"
  type        = list(string)
}

# ==============================================================================
# INSTANCE CONFIGURATION
# ==============================================================================

variable "instance_type" {
  description = "EC2 instance type (used when instance_types is empty)"
  type        = string
  default     = "t3.medium"
}

variable "instance_types" {
  description = "List of instance types for mixed instances policy (Spot). If empty, uses instance_type"
  type        = list(string)
  default     = []
}

variable "use_spot" {
  description = "Use Spot instances via mixed instances policy"
  type        = bool
  default     = false
}

variable "spot_allocation_strategy" {
  description = "Spot allocation strategy: capacity-optimized, lowest-price, price-capacity-optimized, capacity-optimized-prioritized"
  type        = string
  default     = "price-capacity-optimized"

  validation {
    condition     = contains(["capacity-optimized", "lowest-price", "price-capacity-optimized", "capacity-optimized-prioritized"], var.spot_allocation_strategy)
    error_message = "spot_allocation_strategy must be one of: capacity-optimized, lowest-price, price-capacity-optimized, capacity-optimized-prioritized"
  }
}

variable "on_demand_base_capacity" {
  description = "Minimum number of On-Demand instances before using Spot"
  type        = number
  default     = 0
}

variable "on_demand_percentage" {
  description = "Percentage of On-Demand instances above base capacity (0-100)"
  type        = number
  default     = 0

  validation {
    condition     = var.on_demand_percentage >= 0 && var.on_demand_percentage <= 100
    error_message = "on_demand_percentage must be between 0 and 100"
  }
}

variable "key_name" {
  description = "SSH key pair name (optional, prefer SSM Session Manager)"
  type        = string
  default     = null
}

# ==============================================================================
# AMI CONFIGURATION
# ==============================================================================

variable "ami_id" {
  description = "Custom AMI ID (overrides SSM lookup if provided)"
  type        = string
  default     = null
}

variable "ami_type" {
  description = "AMI type for SSM lookup: standard, gpu (AL2023), gpu-al2 (legacy AL2), arm64, inferentia"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "gpu", "gpu-al2", "arm64", "inferentia"], var.ami_type)
    error_message = "ami_type must be one of: standard, gpu, gpu-al2, arm64, inferentia"
  }
}

# ==============================================================================
# AUTO SCALING GROUP
# ==============================================================================

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Initial desired capacity of the ASG"
  type        = number
  default     = 1
}

variable "health_check_grace_period" {
  description = "Seconds before health checks start after instance launch"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "Health check type: EC2 or ELB (use ELB when instances are behind a load balancer)"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be either EC2 or ELB"
  }
}

variable "protect_from_scale_in" {
  description = "Enable scale-in protection for managed termination"
  type        = bool
  default     = true
}

variable "max_instance_lifetime" {
  description = "Maximum instance lifetime in seconds (0 = disabled, min 86400)"
  type        = number
  default     = 0
}

variable "instance_refresh_enabled" {
  description = "Enable automatic instance refresh on launch template changes"
  type        = bool
  default     = true
}

variable "instance_refresh_min_healthy" {
  description = "Minimum healthy percentage during instance refresh"
  type        = number
  default     = 50
}

variable "enabled_metrics" {
  description = "Enable ASG CloudWatch metrics collection"
  type        = bool
  default     = true
}

# ==============================================================================
# EBS VOLUME CONFIGURATION
# ==============================================================================

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type: gp3, gp2, io1, io2"
  type        = string
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "IOPS for gp3/io1/io2 volumes"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Throughput in MiB/s for gp3 volumes"
  type        = number
  default     = 125
}

variable "root_volume_encrypted" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key ID for EBS encryption (null = AWS managed key)"
  type        = string
  default     = null
}

# ==============================================================================
# CAPACITY PROVIDER CONFIGURATION
# ==============================================================================

variable "capacity_provider_name" {
  description = "Custom capacity provider name (defaults to {cluster_name}-{suffix})"
  type        = string
  default     = null
}

variable "managed_scaling_enabled" {
  description = "Enable ECS managed scaling"
  type        = bool
  default     = true
}

variable "target_capacity" {
  description = "Target capacity utilization percentage (1-100). Use 100 for reactive scaling (no headroom buffer). Lower values (e.g. 80) pre-provision extra instances for faster task placement."
  type        = number
  default     = 100

  validation {
    condition     = var.target_capacity >= 1 && var.target_capacity <= 100
    error_message = "target_capacity must be between 1 and 100"
  }
}

variable "minimum_scaling_step_size" {
  description = "Minimum number of instances to scale at once"
  type        = number
  default     = 1
}

variable "maximum_scaling_step_size" {
  description = "Maximum number of instances to scale at once"
  type        = number
  default     = 10
}

variable "instance_warmup_period" {
  description = "Instance warmup period in seconds"
  type        = number
  default     = 300
}

variable "managed_termination_protection" {
  description = "Prevent termination of instances with running tasks"
  type        = bool
  default     = true
}

variable "managed_draining" {
  description = "Enable graceful task draining on scale-in"
  type        = bool
  default     = true
}

# ==============================================================================
# ECS AGENT CONFIGURATION
# ==============================================================================

variable "ecs_reserved_memory" {
  description = "Memory reserved for ECS agent and system processes (MiB)"
  type        = number
  default     = 256
}

variable "ecs_enable_spot_draining" {
  description = "Handle Spot instance interruption notices gracefully"
  type        = bool
  default     = true
}

variable "ecs_container_instance_tags" {
  description = "Tags to apply to ECS container instances"
  type        = map(string)
  default     = {}
}

variable "ecs_log_level" {
  description = "ECS agent log level: debug, info, warn, error"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.ecs_log_level)
    error_message = "ecs_log_level must be one of: debug, info, warn, error"
  }
}

variable "ecs_enable_container_metadata" {
  description = "Enable container metadata file for tasks"
  type        = bool
  default     = true
}

# ==============================================================================
# GPU CONFIGURATION
# ==============================================================================

variable "gpu_enabled" {
  description = "Enable GPU support (uses GPU AMI and configures NVIDIA runtime)"
  type        = bool
  default     = false
}

# ==============================================================================
# SECURITY CONFIGURATION
# ==============================================================================

variable "security_group_ids" {
  description = "Existing security group IDs to attach to instances"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create a security group for ECS instances"
  type        = bool
  default     = true
}

variable "security_group_source_security_group_ids" {
  description = "List of source security group IDs to allow ingress from (alternative to VPC CIDR). When provided, ingress rules use these SGs instead of the VPC CIDR block."
  type        = list(string)
  default     = []
}

variable "enable_imdsv2" {
  description = "Require IMDSv2 for instance metadata (recommended)"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Attach SSM policy for Session Manager access"
  type        = bool
  default     = true
}

# ==============================================================================
# IAM CONFIGURATION
# ==============================================================================

variable "create_iam_role" {
  description = "Create IAM role and instance profile"
  type        = bool
  default     = true
}

variable "instance_profile_arn" {
  description = "Existing IAM instance profile ARN (required if create_iam_role = false). Note: this must be an instance profile ARN, not a role ARN."
  type        = string
  default     = null
}

variable "additional_iam_policies" {
  description = "Additional IAM policy ARNs to attach to the instance role"
  type        = list(string)
  default     = []
}

# ==============================================================================
# TAGGING
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
