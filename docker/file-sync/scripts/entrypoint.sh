#!/bin/bash
set -euo pipefail

echo "🔄 Starting WordPress File Sync Service..."

# Check if hot reload is enabled
if [ "${ENABLE_HOT_RELOAD:-true}" != "true" ]; then
    echo "🚫 Hot reload is disabled, exiting..."
    exit 0
fi

# Install dependencies if package-lock.json is newer
if [ package-lock.json -nt node_modules/.installed ]; then
    echo "📦 Installing/updating dependencies..."
    npm ci --only=production
    touch node_modules/.installed
fi

# Start the file sync service
echo "🚀 Starting file synchronization..."
exec node index.js