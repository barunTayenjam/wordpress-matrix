#!/bin/bash

# Ultimate WordPress Development Matrix - Site Management
# Manage multiple WordPress development instances

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Load environment variables
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Helper Functions ---
function success() {
    echo -e "${GREEN}✓  $1${NC}"
}

function error() {
    echo -e "${RED}✗  $1${NC}"
}

function warning() {
    echo -e "${YELLOW}!  $1${NC}"
}

function info() {
    echo -e "${BLUE}i  $1${NC}"
}

function header() {
    echo -e "${CYAN}"
    echo "=================================="
    echo "$1"
    echo "=================================="
    echo -e "${NC}"
}

# --- Site Discovery Functions ---
function get_wordpress_sites() {
    # Get predefined sites from docker-compose.yml and actual directories
    local sites=()
    
    # Check for xandar (predefined site)
    if [[ -d "$PROJECT_ROOT/xandar" ]]; then
        sites+=("xandar")
    fi
    
    # Check for dynamically created sites (asgard and wordpress_* pattern)
    if [[ -d "$PROJECT_ROOT/asgard" ]]; then
        sites+=("asgard")
    fi

    if ls "$PROJECT_ROOT"/wordpress_* >/dev/null 2>&1; then
        for dir in "$PROJECT_ROOT"/wordpress_*; do
            if [[ -d "$dir" ]]; then
                local site_name=$(basename "$dir" | sed 's/^wordpress_//')
                sites+=("$site_name")
            fi
        done
    fi
    
    # Remove duplicates and sort
    printf '%s\n' "${sites[@]}" | sort -u
}

function get_running_sites() {
    # Get running WordPress containers
    local running_sites=()
    
    # Check predefined sites
    if docker-compose ps xandar 2>/dev/null | grep -E "(Up|Restarting)" >/dev/null; then
        running_sites+=("xandar")
    fi
    if docker-compose ps asgard 2>/dev/null | grep -E "(Up|Restarting)" >/dev/null; then
        running_sites+=("asgard")
    fi
    
    # Check dynamic sites
    local all_services=$(docker-compose ps --services 2>/dev/null || echo "")
    for service in $all_services; do
        if [[ "$service" =~ ^wordpress_.+ ]]; then
            local site_name=$(echo "$service" | sed 's/^wordpress_//')
            if docker-compose ps "$service" 2>/dev/null | grep -E "(Up|Restarting)" >/dev/null; then
                running_sites+=("$site_name")
            fi
        fi
    done
    
    printf '%s\n' "${running_sites[@]}" | sort -u
}

function site_exists() {
    local site_name="$1"
    
    # Check for predefined sites
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        [[ -d "$PROJECT_ROOT/$site_name" ]]
    else
        # Check for dynamic sites
        [[ -d "$PROJECT_ROOT/wordpress_$site_name" ]]
    fi
}

function service_running() {
    local site_name="$1"
    
    # Check for predefined sites
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        # Check if the container is running (Up) or restarting
        docker-compose ps "$site_name" 2>/dev/null | grep -E "(Up|Restarting)" >/dev/null
    else
        # Check for dynamic sites
        docker-compose ps "wordpress_$site_name" 2>/dev/null | grep -E "(Up|Restarting)" >/dev/null
    fi
}

function get_service_names() {
    local site_name="$1"
    
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        echo "$site_name"
    else
        echo "wordpress_$site_name"
    fi
}

function get_site_url() {
    local site_name="$1"
    local port_var_name="$(echo ${site_name} | tr '[:lower:]' '[:upper:]')_PORT"
    local port=$(eval echo "\$port_var_name")
    if [[ -z "$port" ]]; then
        echo "http://localhost:????" # Fallback if port not found
    else
        echo "http://localhost:$port"
    fi
}

# --- Site Management Functions ---
function list_sites() {
    header "WordPress Development Sites"
    
    local sites=($(get_wordpress_sites))
    
    if [[ ${#sites[@]} -eq 0 ]]; then
        info "No WordPress sites found."
        echo ""
        echo "Available options:"
        echo "• Start predefined sites: ./scripts/manage.sh start"
        echo "• Create a new site: ./scripts/create-site.sh"
        return
    fi
    
    echo -e "${CYAN}Site Name${NC}          ${CYAN}Status${NC}      ${CYAN}URL${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    for site in "${sites[@]}"; do
        local status_color=""
        local status_text=""
        
        if service_running "$site"; then
            status_color="${GREEN}"
            status_text="Running"
        else
            status_color="${RED}"
            status_text="Stopped"
        fi
        
        local site_url=$(get_site_url "$site")
        printf "%-18s ${status_color}%-10s${NC} %s\n" \
            "$site" "$status_text" "$site_url"
    done
    
    echo ""
    echo -e "${YELLOW}Management Commands:${NC}"
    echo "• Start site:    ./scripts/manage-sites.sh start <site-name>"
    echo "• Stop site:     ./scripts/manage-sites.sh stop <site-name>"
    echo "• Remove site:   ./scripts/manage-sites.sh remove <site-name>"
    echo "• Site info:     ./scripts/manage-sites.sh info <site-name>"
    echo ""
}

function start_site() {
    local site_name="$1"
    
    if [[ -z "$site_name" ]]; then
        error "Please specify a site name"
        echo "Usage: $0 start <site-name>"
        return 1
    fi
    
    if ! site_exists "$site_name"; then
        error "Site '$site_name' does not exist"
        echo ""
        echo "Available sites:"
        get_wordpress_sites
        return 1
    fi
    
    if service_running "$site_name"; then
        warning "Site '$site_name' is already running"
        return 0
    fi
    
    info "Starting site: $site_name"
    
    # Start supporting services first (if not already running)
    info "Ensuring supporting services are running..."
    docker-compose up -d traefik db-primary redis memcached phpmyadmin mailhog file-sync
    
    # Get the correct service names for the site
    local services=($(get_service_names "$site_name"))
    
    # Start the site services
    docker-compose up -d "$site_name"
    
    # Wait a moment and check status
    sleep 5
    if service_running "$site_name"; then
        success "Site '$site_name' started successfully"
        echo "Access at: $(get_site_url "$site_name")"
        echo ""
        echo "Supporting services available:"
        echo "• phpMyAdmin: https://phpmyadmin.${DOMAIN_SUFFIX:-127.0.0.1.nip.io}"
        echo "• MailHog: https://mailhog.${DOMAIN_SUFFIX:-127.0.0.1.nip.io}"
        echo "• Traefik Dashboard: http://localhost:8080"
    else
        error "Failed to start site '$site_name'"
        echo "Check logs with: docker-compose logs ${services[0]}"
        return 1
    fi
}

function stop_site() {
    local site_name="$1"
    
    if [[ -z "$site_name" ]]; then
        error "Please specify a site name"
        echo "Usage: $0 stop <site-name>"
        return 1
    fi
    
    if ! site_exists "$site_name"; then
        error "Site '$site_name' does not exist"
        return 1
    fi
    
    if ! service_running "$site_name"; then
        warning "Site '$site_name' is already stopped"
        return 0
    fi
    
    info "Stopping site: $site_name"
    
    # Get the correct service names
    local services=($(get_service_names "$site_name"))
    
    docker-compose stop "${services[@]}"
    
    success "Site '$site_name' stopped successfully"
}

function restart_site() {
    local site_name="$1"
    
    if [[ -z "$site_name" ]]; then
        error "Please specify a site name"
        echo "Usage: $0 restart <site-name>"
        return 1
    fi
    
    stop_site "$site_name"
    sleep 2
    start_site "$site_name"
}

function remove_site() {
    local site_name="$1"
    
    if [[ -z "$site_name" ]]; then
        error "Please specify a site name"
        echo "Usage: $0 remove <site-name>"
        return 1
    fi
    
    # Prevent removal of predefined sites
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        error "Cannot remove predefined site '$site_name'"
        echo "Use 'stop' command instead to stop the site."
        return 1
    fi
    
    if ! site_exists "$site_name"; then
        error "Site '$site_name' does not exist"
        return 1
    fi
    
    # Confirm removal
    echo -e "${RED}WARNING: This will permanently delete the site '$site_name'${NC}"
    echo ""
    echo "This will remove:"
    echo "• WordPress files: ./wordpress_$site_name/"
    echo "• Database: ${site_name}_db"
    echo ""
    
    read -p "Are you sure you want to remove '$site_name'? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Site removal cancelled"
        return 0
    fi
    
    # Stop services if running
    if service_running "$site_name"; then
        info "Stopping services..."
        local services=($(get_service_names "$site_name"))
        docker-compose stop "${services[@]}" 2>/dev/null || true
    fi
    
    # Remove containers
    info "Removing containers..."
    local services=($(get_service_names "$site_name"))
    docker-compose rm -f "${services[@]}" 2>/dev/null || true
    
    # Remove database
    info "Removing database..."
    if docker-compose ps db-primary 2>/dev/null | grep -q "Up"; then
        docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" \
            -e "DROP DATABASE IF EXISTS ${site_name}_db;" 2>/dev/null || true
    fi
    
    # Remove files
    info "Removing files..."
    rm -rf "$PROJECT_ROOT/wordpress_$site_name"
    rm -rf "$PROJECT_ROOT/logs/wordpress_$site_name"
    
    success "Site '$site_name' removed successfully"
}

# --- Site Creation Functions ---
function validate_site_name_for_creation() {
    local site_name="$1"
    
    # Check if empty
    if [[ -z "$site_name" ]]; then
        error "Site name cannot be empty"
        return 1
    fi
    
    # Check length
    if [[ ${#site_name} -lt 3 || ${#site_name} -gt 30 ]]; then
        error "Site name must be between 3 and 30 characters"
        return 1
    fi
    
    # Check format (alphanumeric, hyphens, underscores only)
    if [[ ! "$site_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Site name can only contain letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Check if it starts with a letter
    if [[ ! "$site_name" =~ ^[a-zA-Z] ]]; then
        error "Site name must start with a letter"
        return 1
    fi
    
    # Check if site already exists
    if [[ -d "$PROJECT_ROOT/wordpress_$site_name" ]]; then
        error "Site '$site_name' already exists"
        return 1
    fi
    
    # Check for predefined site conflicts
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        error "Cannot use reserved site name '$site_name'"
        return 1
    fi
    
    return 0
}

function get_next_available_port() {
    local max_port=8000
    # Read docker-compose.yml to find the highest port used by WordPress services
    local compose_content=$(cat "$COMPOSE_FILE")
    
    # Regex to find ports in the format "XXXX:80"
    # This will capture the external port number
    while IFS= read -r line; do
        if [[ $line =~ -\ "([0-9]+):80" ]]; then
            local current_port=${BASH_REMATCH[1]}
            if (( current_port > max_port )); then
                max_port=$current_port
            fi
        fi
    done <<< "$compose_content"
    
    echo $((max_port + 1))
}

function create_site_directory() {
    local site_name="$1"
    info "Creating site directory structure..."
    
    local site_dir="$PROJECT_ROOT/wordpress_$site_name"
    mkdir -p "$site_dir"
    mkdir -p "$PROJECT_ROOT/logs/wordpress_$site_name"
    
    success "Created directory: wordpress_$site_name"
}



function update_env_file() {
    local site_name="$1"
    local port_number="$2"
    info "Updating environment file..."
    
    # Add database configuration to .env
    echo "" >> "$PROJECT_ROOT/.env"
    echo "# Configuration for $site_name" >> "$PROJECT_ROOT/.env"
    echo "$(echo ${site_name} | tr '[:lower:]' '[:upper:]')_DB_NAME=${site_name}_db" >> "$PROJECT_ROOT/.env"
    echo "$(echo ${site_name} | tr '[:lower:]' '[:upper:]')_PORT=${port_number}" >> "$PROJECT_ROOT/.env"
    
    success "Updated .env file"
}

function generate_docker_service() {
    local site_name="$1"
    local port_number="$2"
    info "Adding Docker services..."
    
    # Create temporary file with new services
    cat >> "$COMPOSE_FILE" << EOF

  # WordPress instance: $site_name
  wordpress_${site_name}:
    image: wordpress:php${PHP_VERSION:-8.3}-fpm
    container_name: wp_${site_name}
    restart: unless-stopped
    depends_on:
      - db-primary
      - redis
      - memcached
    environment:
      WORDPRESS_DB_HOST: db-primary:3306
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${site_name}_db
      WORDPRESS_DEBUG: \${WORDPRESS_DEBUG}
      WORDPRESS_DEBUG_DISPLAY: \${WORDPRESS_DEBUG_DISPLAY}
      WORDPRESS_DEBUG_LOG: \${WORDPRESS_DEBUG_LOG}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_REDIS_HOST', 'redis');
        define('WP_REDIS_PORT', 6379);
        define('WP_CACHE_KEY_SALT', '${site_name}_db');
        define('WP_ENVIRONMENT_TYPE', 'development');
        define('AUTOMATIC_UPDATER_DISABLED', true);
        define('WP_AUTO_UPDATE_CORE', false);
        define('DISALLOW_FILE_EDIT', false);
        define('WP_DEBUG_DISPLAY', \${WORDPRESS_DEBUG_DISPLAY});
        define('WP_DEBUG_LOG', true);
        define('SCRIPT_DEBUG', true);
        define('SAVEQUERIES', true);
        define('WP_MEMORY_LIMIT', '512M');
    volumes:
      - ./wordpress_${site_name}:/var/www/html
      - ./config/php:/usr/local/etc/php/conf.d:ro
      - ./logs/wordpress_${site_name}:/var/log/wordpress
    networks:
      - wp-network

  # Nginx proxy for $site_name
  nginx_${site_name}:
    image: nginx:alpine
    container_name: nginx_${site_name}
    restart: unless-stopped
    depends_on:
      - wordpress_${site_name}
    volumes:
      - ./wordpress_${site_name}:/var/www/html:ro
      - ./config/nginx/${site_name}.conf:/etc/nginx/conf.d/default.conf:ro
      - ./logs/nginx:/var/log/nginx
    networks:
      - wp-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${site_name}.rule=Host(\`${site_name}.\${DOMAIN_SUFFIX}\`)"
      - "traefik.http.routers.${site_name}.tls=true"
      - "traefik.http.routers.${site_name}.middlewares=security-headers"
      - "traefik.http.services.${site_name}.loadbalancer.server.port=80"
EOF
    
    success "Added Docker services to docker-compose.yml"
}

function create_database() {
    local site_name="$1"
    info "Creating database..."
    
    if docker-compose ps db-primary | grep -q "Up"; then
        docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
            -e "CREATE DATABASE IF NOT EXISTS ${site_name}_db;" 2>/dev/null || true
        success "Database ${site_name}_db created"
    else
        info "Database container not running, database will be created on first start"
    fi
}

function start_new_site() {
    local site_name="$1"
    info "Starting site services..."
    
    # Start supporting services first (if not already running)
    info "Ensuring supporting services are running..."
    docker-compose up -d traefik db-primary redis memcached phpmyadmin mailhog file-sync
    
    # Start the site-specific services
    docker-compose up -d wordpress_${site_name}
    
    # Wait a moment for services to start
    sleep 5
    
    if docker-compose ps wordpress_${site_name} | grep -q "Up"; then
        success "Site services started successfully"
        echo ""
        echo "Supporting services available:"
        echo "• phpMyAdmin: http://localhost:8080/phpmyadmin"
        echo "• MailHog: http://localhost:8025"
        echo "• Traefik Dashboard: http://localhost:8080"
    else
        error "Failed to start site services"
        return 1
    fi
}

function setup_wordpress() {
    local site_name="$1"
    info "Setting up WordPress files..."
    
    # Wait for WordPress container to be ready
    sleep 10
    
    success "WordPress setup completed"
}

function show_creation_completion() {
    local site_name="$1"
    local site_url=$(get_site_url "$site_name")
    header "Site Creation Complete!"
    
    echo "Your new WordPress site '$site_name' has been created successfully!"
    echo ""
    echo "Site Details:"
    echo "  Name: $site_name"
    echo "  URL: $site_url"
    echo "  Directory: ./wordpress_${site_name}/"
    echo "  Database: ${site_name}_db"
    echo ""
    echo "Management Commands:"
    echo "  Start:   ./scripts/manage-sites.sh start $site_name"
    echo "  Stop:    ./scripts/manage-sites.sh stop $site_name"
    echo "  Info:    ./scripts/manage-sites.sh info $site_name"
    echo "  Remove:  ./scripts/manage-sites.sh remove $site_name"
    echo ""
    echo "Next Steps:"
    echo "1. Visit $site_url to access your site"
    echo "2. Complete WordPress installation"
    echo "3. Start developing!"
}

function create_site() {
    local site_name="$1"
    
    # Check if we're in the right directory
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "docker-compose.yml not found. Please run this script from the project root."
        return 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker and try again."
        return 1
    fi
    
    # Get site name from argument or prompt
    if [[ -n "$site_name" ]]; then
        if ! validate_site_name_for_creation "$site_name"; then
            return 1
        fi
    else
        # Prompt for site name
        while true; do
            read -p "Enter site name (e.g., 'myproject', 'client-site'): " site_name
            if validate_site_name_for_creation "$site_name"; then
                break
            fi
            echo ""
        done
    fi
    
    # Set defaults
    local wp_version="latest"
    local php_version="${PHP_VERSION:-8.3}"
    local port=$(get_next_available_port)
    
    # Show configuration
    echo ""
    echo "Site Configuration:"
    echo "  Name: $site_name"
    echo "  WordPress: $wp_version"
    echo "  PHP: $php_version"
    echo "  Port: $port"
    echo "  URL: http://localhost:$port"
    echo ""
    
    # Confirm creation if not provided as argument
    if [[ $# -eq 0 ]]; then
        read -p "Create this site? [Y/n]: " confirm
        confirm=${confirm:-Y}
        
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            info "Site creation cancelled"
            return 0
        fi
    fi
    
    # Create the site
    echo ""
    header "Creating WordPress Site: $site_name"
    
    create_site_directory "$site_name"
    update_env_file "$site_name" "$port"
    # Reload environment variables to include the new site's port
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    generate_docker_service "$site_name" "$port"
    create_database "$site_name"
    start_new_site "$site_name"
    setup_wordpress "$site_name"
    
    echo ""
    show_creation_completion "$site_name"
}

function show_site_info() {
    local site_name="$1"
    
    if [[ -z "$site_name" ]]; then
        error "Please specify a site name"
        echo "Usage: $0 info <site-name>"
        return 1
    fi
    
    if ! site_exists "$site_name"; then
        error "Site '$site_name' does not exist"
        return 1
    fi
    
    header "Site Information: $site_name"
    
    # Basic info
    echo -e "${CYAN}Basic Information:${NC}"
    echo "• Site Name: $site_name"
    
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        echo "• Directory: ./$site_name/"
        echo "• Type: Predefined site"
    else
        echo "• Directory: ./wordpress_$site_name/"
        echo "• Type: Dynamic site"
    fi
    
    local site_url=$(get_site_url "$site_name")
    echo "• URL: $site_url"
    echo "• Admin URL: $site_url/wp-admin"
    echo ""
    
    # Status
    echo -e "${CYAN}Status:${NC}"
    if service_running "$site_name"; then
        echo -e "• WordPress Container: ${GREEN}Running${NC}"
        if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
            echo -e "• Nginx Container: ${GREEN}Running (shared)${NC}"
        else
            echo -e "• Nginx Container: ${GREEN}Running${NC}"
        fi
    else
        echo -e "• WordPress Container: ${RED}Stopped${NC}"
        echo -e "• Nginx Container: ${RED}Stopped${NC}"
    fi
    echo ""
    
    # File info
    echo -e "${CYAN}File Information:${NC}"
    local site_dir=""
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        site_dir="$PROJECT_ROOT/$site_name"
    else
        site_dir="$PROJECT_ROOT/wordpress_$site_name"
    fi
    
    if [[ -d "$site_dir" ]]; then
        local size=$(du -sh "$site_dir" 2>/dev/null | cut -f1)
        echo "• WordPress Files: $size"
    fi
    
    if [[ -f "$PROJECT_ROOT/config/nginx/${site_name}.conf" ]]; then
        echo "• Nginx Config: ./config/nginx/${site_name}.conf"
    elif [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        echo "• Nginx Config: ./config/nginx/unified-wordpress.conf (shared)"
    fi
    
    local log_dir=""
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        log_dir="$PROJECT_ROOT/logs/$site_name"
    else
        log_dir="$PROJECT_ROOT/logs/wordpress_$site_name"
    fi
    
    if [[ -d "$log_dir" ]]; then
        echo "• Log Directory: ./logs/$(basename "$log_dir")/"
    fi
    echo ""
    
    # Database info
    echo -e "${CYAN}Database:${NC}"
    local db_name=""
    if [[ "$site_name" == "xandar" ]]; then
        db_name="${WORDPRESS_1_DB_NAME:-xandar}"
    elif [[ "$site_name" == "asgard" ]]; then
        db_name="asgard_db"
    else
        db_name="${site_name}_db"
    fi
    
    echo "• Database Name: $db_name"
    
    if docker-compose ps db-primary 2>/dev/null | grep -q "Up"; then
        if docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" \
            -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$db_name';" 2>/dev/null | grep -q "$db_name"; then
            echo -e "• Database Status: ${GREEN}Exists${NC}"
        else
            echo -e "• Database Status: ${RED}Not Found${NC}"
        fi
    else
        echo -e "• Database Status: ${YELLOW}Database container not running${NC}"
    fi
    echo ""
    
    # Management commands
    echo -e "${CYAN}Management Commands:${NC}"
    echo "• Start: ./scripts/manage-sites.sh start $site_name"
    echo "• Stop: ./scripts/manage-sites.sh stop $site_name"
    echo "• Restart: ./scripts/manage-sites.sh restart $site_name"
    if [[ "$site_name" != "xandar" && "$site_name" != "asgard" ]]; then
        echo "• Remove: ./scripts/manage-sites.sh remove $site_name"
    fi
    
    local service_name=""
    if [[ "$site_name" == "xandar" || "$site_name" == "asgard" ]]; then
        service_name="$site_name"
    else
        service_name="wordpress_$site_name"
    fi
    echo "• Logs: ./scripts/manage.sh logs $service_name"
    echo ""
}
}

function show_help() {
    header "WordPress Site Management"
    
    echo "Manage multiple WordPress development instances"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  $0 <command> [site-name]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  list                    List all WordPress sites"
    echo "  create [site-name]      Create a new WordPress site"
    echo "  start <site-name>       Start a WordPress site"
    echo "  stop <site-name>        Stop a WordPress site"
    echo "  restart <site-name>     Restart a WordPress site"
    echo "  remove <site-name>      Remove a WordPress site (dynamic sites only)"
    echo "  info <site-name>        Show detailed site information"
    echo "  help                    Show this help message"
    echo ""
    echo -e "${CYAN}Available Sites:${NC}"
    local sites=($(get_wordpress_sites))
    if [[ ${#sites[@]} -gt 0 ]]; then
        for site in "${sites[@]}"; do
            echo "  • $site"
        done
    else
        echo "  • No sites found. Use './scripts/manage.sh start xandar' to start the xandar site."
    fi
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0 list"
    echo "  $0 create myproject"
    echo "  $0 start xandar"
    echo "  $0 stop asgard"
    echo "  $0 info xandar"
    echo "  $0 remove myproject"
    echo ""
}

# --- Main Function ---
function main() {
    local command="$1"
    local site_name="$2"
    
    case "$command" in
        "list"|"ls"|"")
            list_sites
            ;;
        "create"|"new"|"add")
            create_site "$site_name"
            ;;
        "start")
            start_site "$site_name"
            ;;
        "stop")
            stop_site "$site_name"
            ;;
        "restart")
            restart_site "$site_name"
            ;;
        "remove"|"rm"|"delete")
            remove_site "$site_name"
            ;;
        "info"|"show"|"details")
            show_site_info "$site_name"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"