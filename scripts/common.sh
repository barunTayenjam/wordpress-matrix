#!/bin/bash
# Common functions for all maintenance scripts

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Load environment
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Docker compose detection
if command -v podman-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="podman-compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    log_error "Neither docker-compose nor podman-compose found"
    exit 1
fi

# Get all sites
get_sites() {
    local sites=()
    for dir in "$PROJECT_ROOT"/wp_*; do
        if [[ -d "$dir" ]]; then
            sites+=("$(basename "$dir" | sed 's/^wp_//')")
        fi
    done
    printf '%s\n' "${sites[@]}" | sort -u
}

# Check if site exists
site_exists() {
    local site_name="$1"
    [[ -d "$PROJECT_ROOT/wp_$site_name" ]]
}

# Get site port from compose file
get_site_port() {
    local site="$1"
    grep -A 15 "nginx_$site:" "$COMPOSE_FILE" 2>/dev/null | \
        grep -E '^\s*-\s*"[0-9]+:80"' | \
        grep -oE '[0-9]+' | head -1
}

# Get next available port
get_next_port() {
    local max_port=8100
    if [[ -f "$COMPOSE_FILE" ]]; then
        local ports=$(grep -oE '^\s*-\s*"[0-9]+:80"' "$COMPOSE_FILE" 2>/dev/null | \
            grep -oE '[0-9]+:80' | grep -oE '^[0-9]+' | sort -nr)
        if [[ -n "$ports" ]]; then
            max_port=$(echo "$ports" | head -n 1)
        fi
    fi
    ((max_port++))
    while ss -tln 2>/dev/null | grep -q ":$max_port " 2>/dev/null; do
        ((max_port++))
    done
    echo "$max_port"
}

# Create database
create_database() {
    local site="$1"
    local db_name="${site}_db"

    $DOCKER_COMPOSE exec db mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e \
        "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
}

# Update docker-compose.yml (simplified)
update_compose_file() {
    local site="$1"
    log_info "Please manually add $site to docker-compose.yml or use: ./matrix create $site"
}
