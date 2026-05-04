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

# Cross-platform port check (lsof on macOS, ss on Linux)
port_in_use() {
    local port="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        lsof -iTCP:"$port" -sTCP:LISTEN -P -n >/dev/null 2>&1
    else
        ss -tln 2>/dev/null | grep -q ":${port} "
    fi
}

# Ensure wp-cli container is running (it uses profiles: [tools])
ensure_wp_cli_running() {
    if ! $DOCKER_COMPOSE ps wp-cli 2>/dev/null | grep -q "Up"; then
        log_info "Starting wp-cli container..."
        $DOCKER_COMPOSE --profile tools up -d wp-cli >/dev/null 2>&1
        sleep 2
    fi
}

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
    while port_in_use "$max_port"; do
        ((max_port++))
    done
    echo "$max_port"
}

# Create database
create_database() {
    local site="$1"
    local db_name="${site}_db"

    $DOCKER_COMPOSE exec db mysql -u"${MYSQL_USER:-wp_user}" -p"${MYSQL_PASSWORD:-wp_password}" -e \
        "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
}

# Update docker-compose.yml to add a new site service
update_compose_file() {
    local site="$1"
    local port

    # Get next available port
    port=$(get_next_port)

    log_info "Adding site '$site' to docker-compose.yml (port $port)..."

    local temp_file=$(mktemp)

    # Copy everything before the volumes: section
    awk '/^volumes:/ {exit} {print}' "$COMPOSE_FILE" > "$temp_file"

    # Add new service definition
    cat >> "$temp_file" << EOF

  # WordPress site: $site
  wp_$site:
    image: wordpress:php8.3-apache
    container_name: wp_$site
    restart: unless-stopped
    ports:
      - "$port:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: \${MYSQL_USER:-wp_user}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD:-wp_password}
      WORDPRESS_DB_NAME: ${site}_db
      WORDPRESS_DEBUG: \${WP_DEBUG:-true}
    volumes:
      - ./wp_$site:/var/www/html
    networks:
      - wp-net
    depends_on:
      db:
        condition: service_healthy

EOF

    # Copy the volumes: section and everything after
    awk '/^volumes:/ {print; while(getline) print}' "$COMPOSE_FILE" >> "$temp_file"

    mv "$temp_file" "$COMPOSE_FILE"
    log_info "Site '$site' added to docker-compose.yml"
}

# Create nginx configuration for a site
create_nginx_config() {
    local site="$1"
    local nginx_conf_dir="$PROJECT_ROOT/config/nginx"
    local nginx_conf_path="$nginx_conf_dir/$site.conf"

    # Skip if site uses Apache (no nginx needed)
    if grep -A 5 "wp_${site}:" "$COMPOSE_FILE" 2>/dev/null | grep -qE 'image:.*-apache'; then
        log_info "Site '$site' uses Apache — skipping nginx config"
        return 0
    fi

    mkdir -p "$nginx_conf_dir"

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
        fastcgi_buffer_size 32k;
        fastcgi_buffers 16 16k;
        fastcgi_busy_buffers_size 32k;
    }

    location ~ /\. {
        deny all;
    }
}
EOF
    log_info "Created nginx config: $nginx_conf_path"
}
