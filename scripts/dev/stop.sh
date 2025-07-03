#!/bin/bash
# Stop WordPress Development Environment

set -euo pipefail

echo "🛑 Stopping WordPress Development Environment..."

# Stop all services
docker-compose down

echo "✅ All services stopped"
echo ""
echo "💡 To start again: ./scripts/dev/start.sh"
echo "🗑️  To remove all data: docker-compose down -v"