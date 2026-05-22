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

# Get all sites
get_sites() {
    local sites=()
    for dir in "$PROJECT_ROOT"/wp_*; do
        if [[ -d "$dir" ]]; then
            local base_dir="${dir##*/}"
            local site_name="${base_dir#wp_}"
            if [[ -n "$site_name" && "$site_name" != "content" ]]; then
                sites+=("$site_name")
            fi
        fi
    done
    printf '%s\n' "${sites[@]}" | sort -u
}

# Check if site exists
site_exists() {
    local site_name="$1"
    [[ -d "$PROJECT_ROOT/wp_$site_name" ]]
}

validate_site_name() {
    local site_name="${1:-}"
    local reserved_names=" frontend matrix db redis phpmyadmin nginx content "

    if [[ -z "$site_name" ]]; then
        log_error "Site name required"
        return 1
    fi
    if [[ ! "$site_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        log_error "Invalid site name '$site_name'. Use a letter first, then letters, numbers, hyphens, or underscores."
        return 1
    fi
    local site_name_lc
    site_name_lc=$(echo "$site_name" | tr '[:upper:]' '[:lower:]')
    if [[ "$reserved_names" == *" $site_name_lc "* ]]; then
        log_error "'$site_name' is a reserved site name"
        return 1
    fi
}

# Get site port from compose file
get_site_port() {
    local site="$1"
    local port=""
    port=$(grep -A 15 "nginx_$site:" "$COMPOSE_FILE" 2>/dev/null | \
        grep -E '^\s*-\s*"[0-9]+:80"' | \
        grep -oE '[0-9]+' | head -1 || true)
    if [[ -z "$port" ]]; then
        port=$($CONTAINER_RUNTIME port "nginx_$site" 2>/dev/null | grep '80/tcp' | head -1 | sed 's/.*://' | tr -d ' ' || true)
    fi
    echo "$port"
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

port_in_use() {
    local port="${1:-}"
    [[ -z "$port" ]] && return 1
    if command -v lsof >/dev/null 2>&1 && lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
        return 0
    fi
    if command -v ss >/dev/null 2>&1 && ss -tln 2>/dev/null | grep -q ":$port "; then
        return 0
    fi
    $CONTAINER_RUNTIME ps --format "{{.Ports}}" 2>/dev/null | grep -q ":$port->"
}

# Create database
create_database() {
    local site="$1"
    validate_site_name "$site" || return 1
    local db_name="${site}_db"

    $CONTAINER_RUNTIME exec wp_db mysql -u root -p"${MYSQL_ROOT_PASSWORD:-root}" -e \
        "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '${MYSQL_USER:-wp_user}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null
}

get_db_network() {
    $CONTAINER_RUNTIME inspect wp_db --format '{{range $name, $_ := .NetworkSettings.Networks}}{{println $name}}{{end}}' 2>/dev/null | head -1
}

run_wp_cli() {
    local site="$1"
    shift
    validate_site_name "$site" || return 1

    local db_network
    db_network=$(get_db_network)
    if [[ -z "$db_network" ]]; then
        log_error "Could not determine database container network"
        return 1
    fi

    $CONTAINER_RUNTIME run --rm \
        -v "$PROJECT_ROOT":/var/www/html:rw \
        -w /var/www/html \
        --network "$db_network" \
        -e WORDPRESS_DB_HOST=db:3306 \
        -e WORDPRESS_DB_USER="${MYSQL_USER:-wp_user}" \
        -e WORDPRESS_DB_PASSWORD="${MYSQL_PASSWORD:-wp_password}" \
        -e WORDPRESS_DB_NAME="${site}_db" \
        wordpress:cli --path="/var/www/html/wp_$site" "$@"
}

# Update docker-compose.yml (simplified)
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
    local temp_file
    temp_file=$(mktemp)
    awk '/^volumes:/ {exit} {if (!/^volumes:/) print}' "$COMPOSE_FILE" > "$temp_file"

    cat >> "$temp_file" << EOF

  # WordPress site: $site
  wp_$site:
    image: wordpress:php8.3-fpm
    container_name: wp_$site
    restart: unless-stopped
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
    mem_limit: 512m
    cpus: 0.5

  nginx_$site:
    image: nginx:alpine
    container_name: nginx_$site
    restart: unless-stopped
    ports:
      - "$port:80"
    depends_on:
      - wp_$site
    volumes:
      - ./wp_$site:/var/www/html:ro
      - $nginx_conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - wp-net
    mem_limit: 128m
    cpus: 0.25

EOF

    awk '/^volumes:/ {print; while(getline) print}' "$COMPOSE_FILE" >> "$temp_file"
    mv "$temp_file" "$COMPOSE_FILE"
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
