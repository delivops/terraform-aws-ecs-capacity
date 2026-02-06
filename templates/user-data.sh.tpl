#!/bin/bash
set -euo pipefail

# ==============================================================================
# ECS EC2 Instance User Data Script
# ==============================================================================

# Enable logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting ECS instance configuration at $(date)"

# Configure ECS Agent
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_RESERVED_MEMORY=${ecs_reserved_memory}
ECS_ENABLE_SPOT_INSTANCE_DRAINING=${ecs_enable_spot_draining}
ECS_ENABLE_CONTAINER_METADATA=${ecs_enable_container_metadata}
ECS_LOGLEVEL=${ecs_log_level}
%{ if ecs_container_instance_tags != "{}" ~}
ECS_CONTAINER_INSTANCE_TAGS=${ecs_container_instance_tags}
%{ endif ~}
EOF

%{ if gpu_enabled ~}
# ==============================================================================
# GPU Configuration
# ==============================================================================

# Enable GPU support in ECS Agent
cat <<'EOFGPU' >> /etc/ecs/ecs.config
ECS_ENABLE_GPU_SUPPORT=true
EOFGPU

# The GPU AMI already has NVIDIA drivers and nvidia-container-runtime installed
# Ensure Docker is configured to use NVIDIA runtime
if [ -f /etc/docker/daemon.json ]; then
  # Backup existing config
  cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
fi

cat > /etc/docker/daemon.json <<'EOFDOCKER'
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOFDOCKER

# Restart Docker to apply changes
systemctl restart docker
%{ endif ~}

# ==============================================================================
# Additional Configuration
# ==============================================================================

# Increase file descriptor limits for containers
cat >> /etc/security/limits.conf <<'EOFLIMITS'
*               soft    nofile          65536
*               hard    nofile          65536
EOFLIMITS

# ==============================================================================
# Pull ECS Agent Container Image (AL2023 requirement)
# ==============================================================================

# On AL2023, ECS agent runs as a container and must be pulled first
echo "Pulling ECS agent container image..."
docker pull public.ecr.aws/ecs/amazon-ecs-agent:latest

# Enable and start ECS agent
systemctl enable ecs
systemctl start ecs
