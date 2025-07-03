#!/bin/bash

# This script resolves common Docker image issues by removing and re-pulling them.

set -e

echo "🔧  Fixing Docker image issues..."

# Images to fix.
# Add any other images that might cause issues.
IMAGES_TO_FIX=(
    "wordpress:php8.3-fpm-alpine"
    "nginx:alpine"
    "mysql:8.0"
    "redis:7-alpine"
    "traefik:v3.0"
    "phpmyadmin:latest"
    "mailhog/mailhog:latest"
    "wordpress:cli-2.8"
)

for image in "${IMAGES_TO_FIX[@]}"; do
    echo "    - Removing and re-pulling '$image'..."
    docker rmi -f "$image" || true
    docker pull "$image"
done

echo "
✅  All images have been refreshed."
echo "You can now try starting the environment again with: ./scripts/manage.sh start"
