#!/bin/bash
# WordPress Development Environment Setup Script

set -euo pipefail

echo "🚀 Setting up WordPress Development Environment..."

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            if [[ $(uname -m) == "arm64" ]]; then
                PLATFORM="mac-silicon"
                echo "🍎 Detected: Mac Silicon (ARM64)"
            else
                PLATFORM="mac-intel"
                echo "🍎 Detected: Mac Intel (x86_64)"
            fi
            ;;
        Linux*)
            if grep -q Microsoft /proc/version 2>/dev/null; then
                PLATFORM="wsl2"
                echo "🐧 Detected: Windows WSL2"
            else
                PLATFORM="linux"
                echo "🐧 Detected: Linux Native"
            fi
            ;;
        *)
            PLATFORM="unknown"
            echo "❓ Unknown platform detected"
            ;;
    esac
}

# Platform-specific optimizations
configure_platform_optimizations() {
    case $PLATFORM in
        "mac-silicon")
            echo "⚡ Applying Mac Silicon optimizations..."
            export DOCKER_DEFAULT_PLATFORM=linux/arm64
            # Enable BuildKit for faster builds
            export DOCKER_BUILDKIT=1
            export COMPOSE_DOCKER_CLI_BUILD=1
            ;;
        "mac-intel")
            echo "⚡ Applying Mac Intel optimizations..."
            export DOCKER_DEFAULT_PLATFORM=linux/amd64
            export DOCKER_BUILDKIT=1
            export COMPOSE_DOCKER_CLI_BUILD=1
            ;;
        "linux")
            echo "⚡ Applying Linux optimizations..."
            # Check and set vm.max_map_count for Elasticsearch
            if [[ $(sysctl -n vm.max_map_count 2>/dev/null || echo 0) -lt 262144 ]]; then
                echo "📝 Setting vm.max_map_count for Elasticsearch..."
                if command -v sudo >/dev/null 2>&1; then
                    echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf >/dev/null
                    sudo sysctl -p >/dev/null 2>&1 || true
                else
                    echo "⚠️  Please run: echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"
                fi
            fi
            ;;
        "wsl2")
            echo "⚡ Applying WSL2 optimizations..."
            # Check if we're in WSL2 filesystem
            if [[ $PWD == /mnt/* ]]; then
                echo "⚠️  For better performance, consider moving project to WSL2 filesystem (~/)"
                echo "   Current location: $PWD"
                echo "   Recommended: ~/wp-dev-platform"
            fi
            ;;
    esac
}

detect_platform
configure_platform_optimizations

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p {logs/{wordpress1,wordpress2},backups,tools}

# Generate secure passwords if not set
if [ ! -f .env.local ]; then
    echo "🔐 Generating secure passwords..."
    cat > .env.local <<EOF
# Auto-generated secure passwords
MYSQL_PASSWORD=$(openssl rand -base64 32)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_REPLICATION_PASSWORD=$(openssl rand -base64 32)
GRAFANA_PASSWORD=$(openssl rand -base64 32)
EOF
    echo "✅ Secure passwords generated in .env.local"
fi

# Generate Traefik auth hash
if ! grep -q "TRAEFIK_AUTH=" .env; then
    echo "🔐 Generating Traefik authentication..."
    TRAEFIK_HASH=$(echo $(htpasswd -nb admin admin) | sed -e s/\\$/\\$\\$/g)
    echo "TRAEFIK_AUTH=$TRAEFIK_HASH" >> .env.local
fi

# Set proper permissions
echo "🔒 Setting file permissions..."
chmod 600 .env .env.local 2>/dev/null || true
chmod +x scripts/**/*.sh 2>/dev/null || true

# Pull latest images
echo "📦 Pulling latest Docker images..."
docker-compose pull

# Build custom images
echo "🔨 Building custom Docker images..."
docker-compose build

echo "✅ Setup completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "   1. Run: docker-compose up -d"
echo "   2. Wait for services to start (2-3 minutes)"
echo "   3. Access your sites:"
echo "      - WordPress 1: https://wordpress1.127.0.0.1.nip.io"
echo "      - WordPress 2: https://wordpress2.127.0.0.1.nip.io"
echo "      - PHPMyAdmin: https://phpmyadmin.127.0.0.1.nip.io"
echo "      - MailHog: https://mailhog.127.0.0.1.nip.io"
echo "      - Grafana: https://grafana.127.0.0.1.nip.io"
echo "      - Traefik: https://traefik.127.0.0.1.nip.io"
echo ""
echo "📚 Documentation: https://github.com/your-repo/wp-dev-platform"