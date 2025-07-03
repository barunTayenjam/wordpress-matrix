#!/bin/bash
# WordPress Instance Manager
# Automates adding and removing WordPress instances

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    cat << EOF
🔧 WordPress Instance Manager

Usage: ./scripts/manage-instances.sh <command> [options]

Commands:
  create <name> [version]   Create a new WordPress instance
  remove <name>             Remove a WordPress instance
  list                      List all WordPress instances
  status                    Show status of all instances
  help                      Show this help message

Examples:
  ./scripts/manage-instances.sh create wordpress3 6.3
  ./scripts/manage-instances.sh create blog latest
  ./scripts/manage-instances.sh remove wordpress3
  ./scripts/manage-instances.sh list

Options:
  name        Instance name (e.g., wordpress3, blog, shop)
  version     WordPress version (e.g., latest, 6.3, 6.2) [default: latest]
EOF
}

# Get next available instance number
get_next_instance_number() {
    local max_num=2
    for dir in wordpress*; do
        if [[ -d "$dir" && "$dir" =~ wordpress([0-9]+) ]]; then
            local num=${BASH_REMATCH[1]}
            if (( num > max_num )); then
                max_num=$num
            fi
        fi
    done
    echo $((max_num + 1))
}

# List existing instances
list_instances() {
    log_info "WordPress Instances:"
    echo ""
    
    local count=0
    for dir in wordpress*; do
        if [[ -d "$dir" ]]; then
            local status="❌ Stopped"
            if docker-compose ps "$dir" 2>/dev/null | grep -q "Up"; then
                status="✅ Running"
            fi
            
            local url="https://${dir}.127.0.0.1.nip.io"
            printf "  %-15s %s  %s\n" "$dir" "$status" "$url"
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        echo "  No WordPress instances found."
    fi
    echo ""
}

# Show instance status
show_status() {
    log_info "Instance Status:"
    docker-compose ps | grep wordpress || echo "No WordPress containers running"
}

# Create new WordPress instance
create_instance() {
    local instance_name=$1
    local wp_version=${2:-latest}
    
    # Validate instance name
    if [[ ! "$instance_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid instance name. Use only letters, numbers, hyphens, and underscores."
        exit 1
    fi
    
    # Check if instance already exists
    if [[ -d "$instance_name" ]]; then
        log_error "Instance '$instance_name' already exists!"
        exit 1
    fi
    
    log_info "Creating WordPress instance: $instance_name (version: $wp_version)"
    
    # Create directory structure
    log_info "Creating directory structure..."
    mkdir -p "$instance_name" "logs/$instance_name"
    
    # Add to .env file
    log_info "Updating environment configuration..."
    local env_name=$(echo "$instance_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    cat >> .env << EOF

# WordPress Instance: $instance_name
WORDPRESS_${env_name}_VERSION=$wp_version
WORDPRESS_${env_name}_DB_NAME=$instance_name
EOF
    
    # Add database creation
    log_info "Adding database configuration..."
    echo "CREATE DATABASE IF NOT EXISTS $instance_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >> config/mysql/init/01-create-databases.sql
    
    # Generate Docker Compose service definition
    log_info "Generating Docker Compose configuration..."
    cat >> docker-compose.yml << EOF

  $instance_name:
    build:
      context: ./docker/wordpress
      dockerfile: Dockerfile
      args:
        - PHP_VERSION=\${PHP_VERSION}
        - WORDPRESS_VERSION=\${WORDPRESS_${env_name}_VERSION}
    container_name: wp_site_${instance_name}
    restart: unless-stopped
    depends_on:
      - db-primary
      - redis
      - memcached
    environment:
      WORDPRESS_DB_HOST: db-primary:3306
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: \${WORDPRESS_${env_name}_DB_NAME}
      WORDPRESS_DEBUG: \${WORDPRESS_DEBUG}
      WORDPRESS_DEBUG_DISPLAY: \${WORDPRESS_DEBUG_DISPLAY}
      WORDPRESS_DEBUG_LOG: \${WORDPRESS_DEBUG_LOG}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_REDIS_HOST', 'redis');
        define('WP_REDIS_PORT', 6379);
        define('WP_CACHE_KEY_SALT', '\${WORDPRESS_${env_name}_DB_NAME}');
        define('ELASTICSEARCH_HOST', 'elasticsearch:9200');
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
      - ./$instance_name:/var/www/html
      - ./config/php:/usr/local/etc/php/conf.d:ro
      - ./logs/$instance_name:/var/log/wordpress
      - ./config/nginx/wordpress.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - wp-network
      - monitoring
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 256M
          cpus: '0.25'
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.$instance_name.rule=Host(\`$instance_name.\${DOMAIN_SUFFIX}\`)"
      - "traefik.http.routers.$instance_name.tls=true"
      - "traefik.http.routers.$instance_name.middlewares=security-headers"
      - "traefik.http.services.$instance_name.loadbalancer.server.port=80"
      - "traefik.http.services.$instance_name.loadbalancer.healthcheck.path=/wp-admin/admin-ajax.php"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost/wp-admin/admin-ajax.php?action=heartbeat || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF
    
    # Update WP-CLI volumes
    log_info "Updating WP-CLI configuration..."
    local wpcli_line=$(grep -n "wpcli:" docker-compose.yml | head -1 | cut -d: -f1)
    local volumes_line=$(tail -n +$wpcli_line docker-compose.yml | grep -n "volumes:" | head -1 | cut -d: -f1)
    volumes_line=$((wpcli_line + volumes_line - 1))
    
    # Add new volume mount after existing ones
    sed -i "${volumes_line}a\\      - ./$instance_name:/var/www/html/$instance_name" docker-compose.yml
    
    # Update file sync configuration
    log_info "Updating file sync configuration..."
    local sync_paths_line=$(grep -n "SYNC_PATHS:" docker-compose.yml | cut -d: -f1)
    if [[ -n "$sync_paths_line" ]]; then
        sed -i "${sync_paths_line}s|\"$|,/app/$instance_name/wp-content/themes,/app/$instance_name/wp-content/plugins\"|" docker-compose.yml
    fi
    
    local reload_containers_line=$(grep -n "RELOAD_CONTAINERS:" docker-compose.yml | cut -d: -f1)
    if [[ -n "$reload_containers_line" ]]; then
        sed -i "${reload_containers_line}s|\"$|,wp_site_${instance_name}\"|" docker-compose.yml
    fi
    
    # Set proper permissions
    chmod 755 "$instance_name" "logs/$instance_name"
    
    log_success "Instance '$instance_name' created successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart the environment: ./wp-dev restart"
    echo "  2. Access your new site: https://$instance_name.127.0.0.1.nip.io"
    echo "  3. Login with: admin/admin"
}

# Remove WordPress instance
remove_instance() {
    local instance_name=$1
    
    # Check if instance exists
    if [[ ! -d "$instance_name" ]]; then
        log_error "Instance '$instance_name' does not exist!"
        exit 1
    fi
    
    log_warning "This will remove all data for instance '$instance_name'"
    echo "This includes:"
    echo "  - WordPress files"
    echo "  - Database data"
    echo "  - Log files"
    echo "  - Configuration"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
    
    log_info "Removing WordPress instance: $instance_name"
    
    # Create backup first
    log_info "Creating backup before removal..."
    if command -v ./wp-dev >/dev/null 2>&1; then
        ./wp-dev backup "$instance_name" || log_warning "Backup failed, continuing with removal"
    fi
    
    # Stop and remove container
    log_info "Stopping container..."
    docker-compose stop "$instance_name" 2>/dev/null || true
    docker-compose rm -f "$instance_name" 2>/dev/null || true
    
    # Remove from Docker Compose file
    log_info "Updating Docker Compose configuration..."
    # This is a complex sed operation to remove the entire service block
    # We'll use a simpler approach and ask user to manually clean up
    log_warning "Please manually remove the '$instance_name' service from docker-compose.yml"
    
    # Remove from .env
    log_info "Updating environment configuration..."
    local env_name=$(echo "$instance_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    sed -i "/WORDPRESS_${env_name}_/d" .env
    
    # Move files to backup location
    log_info "Moving files to backup location..."
    local backup_dir="backups/removed_${instance_name}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -d "$instance_name" ]]; then
        mv "$instance_name" "$backup_dir/"
    fi
    
    if [[ -d "logs/$instance_name" ]]; then
        mv "logs/$instance_name" "$backup_dir/"
    fi
    
    # Remove database (optional)
    read -p "Do you want to remove the database? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing database..."
        docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS $instance_name;" || log_warning "Failed to remove database"
    fi
    
    log_success "Instance '$instance_name' removed successfully!"
    log_info "Backup location: $backup_dir"
    echo ""
    log_info "Next steps:"
    echo "  1. Manually remove the service definition from docker-compose.yml"
    echo "  2. Restart the environment: ./wp-dev restart"
}

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        create)
            if [[ $# -lt 1 ]]; then
                log_error "Instance name is required"
                echo ""
                show_help
                exit 1
            fi
            create_instance "$@"
            ;;
        remove)
            if [[ $# -lt 1 ]]; then
                log_error "Instance name is required"
                echo ""
                show_help
                exit 1
            fi
            remove_instance "$1"
            ;;
        list)
            list_instances
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"