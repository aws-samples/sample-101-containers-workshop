#!/bin/bash
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=wildlife-ecs
ECS_LOGLEVEL=info
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
EOF