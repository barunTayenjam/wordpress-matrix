#!/bin/bash
# Start WordPress Development Environment

set -euo pipefail

echo "🚀 Starting WordPress Development Environment..."

# Check if setup has been run
if [ ! -f .env.local ]; then
    echo "⚠️  Environment not set up. Running setup first..."
    ./scripts/dev/setup.sh
fi

# Start services
echo "🔄 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🏥 Checking service health..."

services=("traefik" "db-primary" "redis" "wordpress1" "wordpress2")
for service in "${services[@]}"; do
    if docker-compose ps "$service" | grep -q "Up"; then
        echo "  ✅ $service is running"
    else
        echo "  ❌ $service is not running"
    fi
done

# Display access information
echo ""
echo "🎉 WordPress Development Environment is ready!"
echo ""
echo "🌐 Access URLs:"
echo "   WordPress 1:  https://wordpress1.127.0.0.1.nip.io"
echo "   WordPress 2:  https://wordpress2.127.0.0.1.nip.io"
echo "   PHPMyAdmin:   https://phpmyadmin.127.0.0.1.nip.io"
echo "   MailHog:      https://mailhog.127.0.0.1.nip.io"
echo "   Grafana:      https://grafana.127.0.0.1.nip.io"
echo "   Traefik:      https://traefik.127.0.0.1.nip.io"
echo ""
echo "🔐 Default Credentials:"
echo "   WordPress:    admin / admin"
echo "   PHPMyAdmin:   wp_dev_user / (see .env)"
echo "   Grafana:      admin / (see .env.local)"
echo "   Traefik:      admin / admin"
echo ""
echo "🛠️  Useful Commands:"
echo "   View logs:    docker-compose logs -f [service]"
echo "   Stop:         docker-compose down"
echo "   Restart:      docker-compose restart [service]"
echo "   Shell:        docker-compose exec [service] bash"
echo ""
echo "📊 Monitoring:"
echo "   docker-compose logs -f"
echo "   docker-compose ps"
echo "   docker stats"