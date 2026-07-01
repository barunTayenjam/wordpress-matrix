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

if [[ "$DOCKER_COMPOSE" == "podman-compose" ]]; then
    CONTAINER_RUNTIME="podman"
else
    CONTAINER_RUNTIME="docker"
fi

# Load shared validation rules
source "$PROJECT_ROOT/config/validation.sh"

# Load shared helper functions
source "$PROJECT_ROOT/scripts/helpers.sh"

# Load compose manipulation (uses helpers for stack detection)
source "$PROJECT_ROOT/scripts/compose-lib.sh"

# Create database
create_database() {
    local site="$1"
    validate_site_name "$site" || return 1
    local db_name="${site}_db"

    $CONTAINER_RUNTIME exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-root}" wp_db mysql -u root -e \
        "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '${MYSQL_USER:-wp_user}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null
}

# Update docker-compose.yml (simplified — nginx stack only; use compose_add_site for apache)
update_compose_file() {
    local site="$1"
    local port="${2:-}"
    validate_site_name "$site" || return 1

    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "docker-compose.yml not found. Run ./matrix repair first."
        return 1
    fi
    if grep -q "^  wp_${site}:" "$COMPOSE_FILE" 2>/dev/null; then
        log_warning "$site is already present in docker-compose.yml"
        return 0
    fi
    if [[ -z "$port" ]]; then
        port=$(get_next_port)
    fi

    local nginx_conf="$PROJECT_ROOT/config/nginx/$site.conf"
    compose_add_site "$site" "${DEFAULT_PHP_VERSION:-8.3}" "$port" "$nginx_conf" "nginx"
    log_success "Added $site to docker-compose.yml on port $port"
}

create_nginx_config() {
    local site="$1"
    validate_site_name "$site" || return 1
    local nginx_dir="$PROJECT_ROOT/config/nginx"
    local nginx_conf_path="$nginx_dir/$site.conf"
    mkdir -p "$nginx_dir"

    cat > "$nginx_conf_path" << EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass wp_$site:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all;
    }
}
EOF
}
