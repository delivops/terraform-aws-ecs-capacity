#!/bin/bash
set -euo pipefail

# ==============================================================================
# ECS EC2 Instance User Data Script
# ==============================================================================
# The AL2023 ECS-optimized AMI ships with ecs-init as a systemd service that
# handles agent pulling, caching, and startup automatically. User-data runs
# before ecs.service (cloud-final.service -> ecs.service ordering), so we only
# need to populate /etc/ecs/ecs.config here.
# ==============================================================================

exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting ECS instance configuration at $(date)"

# Configure ECS Agent — this is the only required step
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

# Enable GPU support in ECS config and set NVIDIA as default Docker runtime
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_ENABLE_GPU_SUPPORT=true
EOF

cat > /etc/docker/daemon.json <<'EOF'
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF

# Restart Docker before ecs.service starts
systemctl restart docker
%{ endif ~}

echo "ECS instance configuration completed at $(date)"




