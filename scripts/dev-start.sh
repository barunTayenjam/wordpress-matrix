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
