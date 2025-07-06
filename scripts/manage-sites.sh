#!/bin/bash

# Ultimate WordPress Development Matrix - Site Management
# Manage multiple WordPress development instances

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

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
    echo -e "${GREEN}✅  $1${NC}"
}

function error() {
    echo -e "${RED}❌  $1${NC}"
}

function warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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
    # Find all wordpress_ directories
    find "$PROJECT_ROOT" -maxdepth 1 -type d -name "wordpress_*" | sed 's|.*/wordpress_||' | sort
}

function get_running_sites() {
    # Get running WordPress containers
    docker-compose ps --services | grep "^wordpress_" | sed 's/^wordpress_//' | sort
}

function site_exists() {
    local site_name="$1"
    [[ -d "$PROJECT_ROOT/wordpress_$site_name" ]]
}

function service_running() {
    local site_name="$1"
    docker-compose ps wordpress_$site_name 2>/dev/null | grep -q "Up"
}

# --- Site Management Functions ---
function list_sites() {
    header "📋 WordPress Development Sites"
    
    local sites=($(get_wordpress_sites))
    
    if [[ ${#sites[@]} -eq 0 ]]; then
        info "No WordPress sites found."
        echo ""
        echo "Create a new site with: ./scripts/create-site.sh"
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
        
        printf "%-18s ${status_color}%-10s${NC} https://%s.127.0.0.1.nip.io\n" \
            "$site" "$status_text" "$site"
    done
    
    echo ""
    echo -e "${YELLOW}💡 Management Commands:${NC}"
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
        return 1
    fi
    
    if service_running "$site_name"; then
        warning "Site '$site_name' is already running"
        return 0
    fi
    
    info "Starting site: $site_name"
    docker-compose up -d wordpress_$site_name nginx_$site_name
    
    # Wait a moment and check status
    sleep 5
    if service_running "$site_name"; then
        success "Site '$site_name' started successfully"
        echo "Access at: https://${site_name}.127.0.0.1.nip.io"
    else
        error "Failed to start site '$site_name'"
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
    docker-compose stop wordpress_$site_name nginx_$site_name
    
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
    
    if ! site_exists "$site_name"; then
        error "Site '$site_name' does not exist"
        return 1
    fi
    
    # Confirm removal
    echo -e "${RED}⚠️  WARNING: This will permanently delete the site '$site_name'${NC}"
    echo ""
    echo "This will remove:"
    echo "• WordPress files: ./wordpress_$site_name/"
    echo "• Database: ${site_name}_db"
    echo "• Nginx configuration"
    echo "• Docker services"
    echo "• Log files"
    echo ""
    
    read -p "Are you sure you want to remove '$site_name'? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Site removal cancelled"
        return 0
    fi
    
    # Stop services if running
    if service_running "$site_name"; then
        info "Stopping services..."
        docker-compose stop wordpress_$site_name nginx_$site_name 2>/dev/null || true
    fi
    
    # Remove containers
    info "Removing containers..."
    docker-compose rm -f wordpress_$site_name nginx_$site_name 2>/dev/null || true
    
    # Remove database
    info "Removing database..."
    if docker-compose ps db-primary | grep -q "Up"; then
        docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" \
            -e "DROP DATABASE IF EXISTS ${site_name}_db;" 2>/dev/null || true
    fi
    
    # Remove files
    info "Removing files..."
    rm -rf "$PROJECT_ROOT/wordpress_$site_name"
    rm -rf "$PROJECT_ROOT/logs/wordpress_$site_name"
    rm -f "$PROJECT_ROOT/config/nginx/${site_name}.conf"
    
    # Remove from docker-compose.yml
    info "Updating Docker configuration..."
    # Create a temporary file without the site's services
    awk -v site="$site_name" '
        /^  # WordPress instance: / && $4 == site { skip=1; next }
        /^  wordpress_/ && $0 ~ site { skip=1; next }
        /^  # Nginx proxy for / && $5 == site { skip=1; next }
        /^  nginx_/ && $0 ~ site { skip=1; next }
        skip && /^  [a-zA-Z]/ && !/^    / { skip=0 }
        !skip { print }
    ' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"
    
    # Remove from .env file
    sed -i.bak "/# Database for $site_name/d" "$PROJECT_ROOT/.env" 2>/dev/null || true
    sed -i.bak "/${site_name^^}_DB_NAME/d" "$PROJECT_ROOT/.env" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/.env.bak"
    
    # Update code quality configurations
    info "Updating code quality configurations..."
    
    # Remove from PHPCS config
    local phpcs_config="$PROJECT_ROOT/config/phpcs/phpcs.xml"
    if [[ -f "$phpcs_config" ]]; then
        sed -i.bak "/wordpress_${site_name}/d" "$phpcs_config"
        rm -f "${phpcs_config}.bak"
    fi
    
    # Remove from PHPStan config
    local phpstan_config="$PROJECT_ROOT/config/phpstan/phpstan.neon"
    if [[ -f "$phpstan_config" ]]; then
        sed -i.bak "/wordpress_${site_name}/d" "$phpstan_config"
        rm -f "${phpstan_config}.bak"
    fi
    
    success "Site '$site_name' removed successfully"
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
    
    header "📋 Site Information: $site_name"
    
    # Basic info
    echo -e "${CYAN}Basic Information:${NC}"
    echo "• Site Name: $site_name"
    echo "• Directory: ./wordpress_$site_name/"
    echo "• URL: https://${site_name}.127.0.0.1.nip.io"
    echo "• Admin URL: https://${site_name}.127.0.0.1.nip.io/wp-admin"
    echo ""
    
    # Status
    echo -e "${CYAN}Status:${NC}"
    if service_running "$site_name"; then
        echo -e "• WordPress Container: ${GREEN}Running${NC}"
        echo -e "• Nginx Container: ${GREEN}Running${NC}"
    else
        echo -e "• WordPress Container: ${RED}Stopped${NC}"
        echo -e "• Nginx Container: ${RED}Stopped${NC}"
    fi
    echo ""
    
    # File info
    echo -e "${CYAN}File Information:${NC}"
    if [[ -d "$PROJECT_ROOT/wordpress_$site_name" ]]; then
        local size=$(du -sh "$PROJECT_ROOT/wordpress_$site_name" 2>/dev/null | cut -f1)
        echo "• WordPress Files: $size"
    fi
    
    if [[ -f "$PROJECT_ROOT/config/nginx/${site_name}.conf" ]]; then
        echo "• Nginx Config: ./config/nginx/${site_name}.conf"
    fi
    
    if [[ -d "$PROJECT_ROOT/logs/wordpress_$site_name" ]]; then
        echo "• Log Directory: ./logs/wordpress_$site_name/"
    fi
    echo ""
    
    # Database info
    echo -e "${CYAN}Database:${NC}"
    echo "• Database Name: ${site_name}_db"
    if docker-compose ps db-primary | grep -q "Up"; then
        local db_exists=$(docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" \
            -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${site_name}_db';" 2>/dev/null | grep -c "${site_name}_db" || echo "0")
        if [[ "$db_exists" -gt 0 ]]; then
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
    echo "• Remove: ./scripts/manage-sites.sh remove $site_name"
    echo "• Logs: ./scripts/manage.sh logs wordpress_$site_name"
    echo ""
}

function show_help() {
    header "🎯 WordPress Site Management"
    
    echo "Manage multiple WordPress development instances"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  $0 <command> [site-name]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  list                    List all WordPress sites"
    echo "  start <site-name>       Start a WordPress site"
    echo "  stop <site-name>        Stop a WordPress site"
    echo "  restart <site-name>     Restart a WordPress site"
    echo "  remove <site-name>      Remove a WordPress site (destructive)"
    echo "  info <site-name>        Show detailed site information"
    echo "  help                    Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0 list"
    echo "  $0 start myproject"
    echo "  $0 stop client-site"
    echo "  $0 info myproject"
    echo "  $0 remove old-site"
    echo ""
    echo -e "${CYAN}Create New Sites:${NC}"
    echo "  ./scripts/create-site.sh"
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