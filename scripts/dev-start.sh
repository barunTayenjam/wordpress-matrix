#!/bin/bash

# Streamlined WordPress Development Environment Startup

set -e

echo "🚀 Starting WordPress Development Environment"
echo "============================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p logs/nginx logs/wordpress1 logs/wordpress2

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

# Wait for WordPress services to be healthy
echo "⏳ Waiting for WordPress instances to be healthy..."
HEALTH_CHECK_TIMEOUT=600 # 10 minutes timeout

for service in wp_site1 wp_site2; do
    echo -n "    - Waiting for '$service' to be healthy... "
    end_time=$((SECONDS + HEALTH_CHECK_TIMEOUT))
    while [ $SECONDS -lt $end_time ]; do
        status=$(docker-compose ps -q $service | xargs docker inspect -f '{{.State.Health.Status}}')
        if [ "$status" == "healthy" ]; then
            echo -e "\033[1;32mHealthy\033[0m"
            break
        fi
        sleep 5
    done

    if [ "$status" != "healthy" ]; then
        echo -e "\033[1;31mFailed\033[0m"
        error "'$service' did not become healthy in time. Check logs with: docker-compose logs $service"
        exit 1
    fi
done

echo ""
echo "✅ WordPress Development Environment is ready!"
echo ""
echo "🌐 Access URLs:"
echo "   WordPress 1: http://wordpress1.127.0.0.1.nip.io"
echo "   WordPress 2: http://wordpress2.127.0.0.1.nip.io"
echo "   Traefik Dashboard: http://traefik.127.0.0.1.nip.io"
echo "   phpMyAdmin: http://phpmyadmin.127.0.0.1.nip.io"
echo "   MailHog: http://mailhog.127.0.0.1.nip.io"
echo ""
echo "📊 Check status: docker-compose ps"
echo "📋 View logs: docker-compose logs -f [service]"