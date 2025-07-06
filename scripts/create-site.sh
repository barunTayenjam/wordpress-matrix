#!/bin/bash

# Ultimate WordPress Development Matrix - Dynamic Site Creator
# Creates new WordPress development instances on demand

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
ENV_FILE="$PROJECT_ROOT/.env"
NGINX_CONFIG_DIR="$PROJECT_ROOT/config/nginx"

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

function step() {
    echo -e "${PURPLE}🔄  $1${NC}"
}

function header() {
    echo -e "${CYAN}"
    echo "=================================="
    echo "$1"
    echo "=================================="
    echo -e "${NC}"
}

# --- Validation Functions ---
function validate_site_name() {
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
    
    # Check if service name conflicts with existing services
    if docker-compose ps | grep -q "wp_${site_name}"; then
        error "Service name conflict: wp_${site_name} already exists"
        return 1
    fi
    
    return 0
}

function get_next_port() {
    # Find the next available port starting from 8001
    local port=8001
    while netstat -tuln 2>/dev/null | grep -q ":$port "; do
        ((port++))
    done
    echo $port
}

# --- Site Creation Functions ---
function prompt_for_site_info() {
    header "🚀 WordPress Site Creator"
    
    echo "This tool will create a new WordPress development instance with:"
    echo "• Dedicated WordPress container"
    echo "• Nginx proxy configuration"
    echo "• Database setup"
    echo "• SSL/TLS with Traefik"
    echo "• Integration with code quality tools"
    echo ""
    
    # Get site name
    while true; do
        read -p "Enter site name (e.g., 'myproject', 'client-site'): " SITE_NAME
        if validate_site_name "$SITE_NAME"; then
            break
        fi
        echo ""
    done
    
    # Get optional description
    read -p "Enter site description (optional): " SITE_DESCRIPTION
    if [[ -z "$SITE_DESCRIPTION" ]]; then
        SITE_DESCRIPTION="WordPress development site: $SITE_NAME"
    fi
    
    # Get WordPress version
    echo ""
    echo "Available WordPress versions:"
    echo "1) Latest (recommended)"
    echo "2) 6.6"
    echo "3) 6.5"
    echo "4) 6.4"
    echo "5) Custom version"
    
    while true; do
        read -p "Select WordPress version [1]: " WP_VERSION_CHOICE
        WP_VERSION_CHOICE=${WP_VERSION_CHOICE:-1}
        
        case $WP_VERSION_CHOICE in
            1) WP_VERSION="latest"; break ;;
            2) WP_VERSION="6.6"; break ;;
            3) WP_VERSION="6.5"; break ;;
            4) WP_VERSION="6.4"; break ;;
            5) 
                read -p "Enter custom WordPress version: " WP_VERSION
                if [[ -n "$WP_VERSION" ]]; then
                    break
                fi
                ;;
            *) echo "Invalid choice. Please select 1-5." ;;
        esac
    done
    
    # Get PHP version
    echo ""
    echo "Available PHP versions:"
    echo "1) PHP 8.3 (recommended)"
    echo "2) PHP 8.2"
    echo "3) PHP 8.1"
    
    while true; do
        read -p "Select PHP version [1]: " PHP_VERSION_CHOICE
        PHP_VERSION_CHOICE=${PHP_VERSION_CHOICE:-1}
        
        case $PHP_VERSION_CHOICE in
            1) PHP_VERSION="8.3"; break ;;
            2) PHP_VERSION="8.2"; break ;;
            3) PHP_VERSION="8.1"; break ;;
            *) echo "Invalid choice. Please select 1-3." ;;
        esac
    done
    
    # Confirm settings
    echo ""
    header "📋 Site Configuration Summary"
    echo "Site Name: $SITE_NAME"
    echo "Description: $SITE_DESCRIPTION"
    echo "WordPress Version: $WP_VERSION"
    echo "PHP Version: $PHP_VERSION"
    echo "URL: https://${SITE_NAME}.127.0.0.1.nip.io"
    echo "Directory: $PROJECT_ROOT/wordpress_$SITE_NAME"
    echo ""
    
    read -p "Create this site? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-Y}
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Site creation cancelled"
        exit 0
    fi
}

function create_site_directory() {
    step "Creating site directory structure..."
    
    local site_dir="$PROJECT_ROOT/wordpress_$SITE_NAME"
    mkdir -p "$site_dir"
    mkdir -p "$PROJECT_ROOT/logs/wordpress_$SITE_NAME"
    
    success "Created directory: wordpress_$SITE_NAME"
}

function generate_docker_service() {
    step "Generating Docker service configuration..."
    
    local service_config="
  # WordPress instance: $SITE_NAME
  wordpress_${SITE_NAME}:
    image: wordpress:${WP_VERSION}-php${PHP_VERSION}-fpm-alpine
    container_name: wp_${SITE_NAME}
    restart: unless-stopped
    depends_on:
      - db-primary
      - redis
      - memcached
    environment:
      WORDPRESS_DB_HOST: db-primary:3306
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${SITE_NAME}_db
      WORDPRESS_DEBUG: \${WORDPRESS_DEBUG}
      WORDPRESS_DEBUG_DISPLAY: \${WORDPRESS_DEBUG_DISPLAY}
      WORDPRESS_DEBUG_LOG: \${WORDPRESS_DEBUG_LOG}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_REDIS_HOST', 'redis');
        define('WP_REDIS_PORT', 6379);
        define('WP_CACHE_KEY_SALT', '${SITE_NAME}');
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
      - ./wordpress_${SITE_NAME}:/var/www/html
      - ./config/php:/usr/local/etc/php/conf.d:ro
      - ./logs/wordpress_${SITE_NAME}:/var/log/wordpress
    networks:
      - wp-network

  # Nginx proxy for $SITE_NAME
  nginx_${SITE_NAME}:
    image: nginx:alpine
    container_name: nginx_${SITE_NAME}
    restart: unless-stopped
    depends_on:
      - wordpress_${SITE_NAME}
    volumes:
      - ./wordpress_${SITE_NAME}:/var/www/html:ro
      - ./config/nginx/${SITE_NAME}.conf:/etc/nginx/conf.d/default.conf:ro
      - ./logs/nginx:/var/log/nginx
    networks:
      - wp-network
    labels:
      - \"traefik.enable=true\"
      - \"traefik.http.routers.${SITE_NAME}.rule=Host(\\\`${SITE_NAME}.127.0.0.1.nip.io\\\`)\"
      - \"traefik.http.routers.${SITE_NAME}.tls=true\"
      - \"traefik.http.routers.${SITE_NAME}.middlewares=security-headers\"
      - \"traefik.http.services.${SITE_NAME}.loadbalancer.server.port=80\"
      - \"traefik.http.services.${SITE_NAME}.loadbalancer.healthcheck.path=/wp-admin/admin-ajax.php\"
    healthcheck:
      test: [\"CMD-SHELL\", \"curl -f http://localhost/wp-admin/admin-ajax.php?action=heartbeat || exit 1\"]
      interval: 30s
      timeout: 10s
      retries: 3
"

    # Add the service to docker-compose.yml
    echo "$service_config" >> "$COMPOSE_FILE"
    
    success "Added Docker service configuration"
}

function create_nginx_config() {
    step "Creating Nginx configuration..."
    
    local nginx_config="server {
    listen 80;
    server_name ${SITE_NAME}.127.0.0.1.nip.io;
    root /var/www/html;
    index index.php index.html index.htm;

    # Site description: $SITE_DESCRIPTION
    # Created: $(date)
    
    # Security headers
    add_header X-Frame-Options \"SAMEORIGIN\" always;
    add_header X-XSS-Protection \"1; mode=block\" always;
    add_header X-Content-Type-Options \"nosniff\" always;
    add_header Referrer-Policy \"no-referrer-when-downgrade\" always;
    add_header Content-Security-Policy \"default-src 'self' http: https: data: blob: 'unsafe-inline'\" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;

    # WordPress specific rules
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \\.php\$ {
        include fastcgi_params;
        fastcgi_intercept_errors on;
        fastcgi_pass wordpress_${SITE_NAME}:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_read_timeout 300;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)\$ {
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }

    # Deny access to sensitive files
    location ~ /\\. {
        deny all;
    }

    location ~ ~\$ {
        deny all;
    }

    # WordPress security
    location ~ ^/(wp-admin|wp-includes)/ {
        location ~ \\.php\$ {
            include fastcgi_params;
            fastcgi_intercept_errors on;
            fastcgi_pass wordpress_${SITE_NAME}:9000;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
    }
}"

    echo "$nginx_config" > "$NGINX_CONFIG_DIR/${SITE_NAME}.conf"
    
    success "Created Nginx configuration: ${SITE_NAME}.conf"
}

function update_env_file() {
    step "Updating environment configuration..."
    
    # Add database name to .env if not exists
    if ! grep -q "${SITE_NAME}_db" "$ENV_FILE"; then
        echo "" >> "$ENV_FILE"
        echo "# Database for $SITE_NAME" >> "$ENV_FILE"
        echo "${SITE_NAME^^}_DB_NAME=${SITE_NAME}_db" >> "$ENV_FILE"
    fi
    
    success "Updated environment configuration"
}

function create_database() {
    step "Creating database..."
    
    # Check if database container is running
    if ! docker-compose ps db-primary | grep -q "Up"; then
        warning "Database container not running. Starting it first..."
        docker-compose up -d db-primary
        sleep 10
    fi
    
    # Create database
    docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" -e "CREATE DATABASE IF NOT EXISTS ${SITE_NAME}_db;"
    docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" -e "GRANT ALL PRIVILEGES ON ${SITE_NAME}_db.* TO '${MYSQL_USER:-wp_dev_user}'@'%';"
    docker-compose exec -T db-primary mysql -u root -p"${MYSQL_ROOT_PASSWORD:-SecureRoot2024!}" -e "FLUSH PRIVILEGES;"
    
    success "Created database: ${SITE_NAME}_db"
}

function start_site() {
    step "Starting WordPress site..."
    
    # Start the new services
    docker-compose up -d wordpress_${SITE_NAME} nginx_${SITE_NAME}
    
    # Wait for services to be ready
    info "Waiting for services to start..."
    sleep 15
    
    # Check if services are running
    if docker-compose ps wordpress_${SITE_NAME} | grep -q "Up"; then
        success "WordPress container started successfully"
    else
        error "Failed to start WordPress container"
        return 1
    fi
    
    if docker-compose ps nginx_${SITE_NAME} | grep -q "Up"; then
        success "Nginx container started successfully"
    else
        error "Failed to start Nginx container"
        return 1
    fi
}

function setup_wordpress() {
    step "Setting up WordPress..."
    
    # Wait for WordPress to be ready
    info "Waiting for WordPress to initialize..."
    sleep 10
    
    # Install WordPress using WP-CLI
    docker-compose run --rm composer wp --path=/app/wordpress_${SITE_NAME} core install \
        --url="https://${SITE_NAME}.127.0.0.1.nip.io" \
        --title="$SITE_DESCRIPTION" \
        --admin_user="admin" \
        --admin_password="admin" \
        --admin_email="admin@${SITE_NAME}.local" \
        --skip-email
    
    success "WordPress installed successfully"
}

function update_code_quality_tools() {
    step "Updating code quality tools configuration..."
    
    # Update PHPCS configuration to include new site
    local phpcs_config="$PROJECT_ROOT/config/phpcs/phpcs.xml"
    if [[ -f "$phpcs_config" ]]; then
        # Add new paths before the closing </ruleset> tag
        sed -i.bak "s|</ruleset>|    <file>/data/wordpress_${SITE_NAME}/wp-content/themes</file>\\
    <file>/data/wordpress_${SITE_NAME}/wp-content/plugins</file>\\
\\
</ruleset>|" "$phpcs_config"
        rm -f "${phpcs_config}.bak"
    fi
    
    # Update PHPStan configuration
    local phpstan_config="$PROJECT_ROOT/config/phpstan/phpstan.neon"
    if [[ -f "$phpstan_config" ]]; then
        # Add new paths to the paths section
        sed -i.bak "s|paths:|paths:\\
        - /app/wordpress_${SITE_NAME}/wp-content/themes\\
        - /app/wordpress_${SITE_NAME}/wp-content/plugins|" "$phpstan_config"
        rm -f "${phpstan_config}.bak"
    fi
    
    success "Updated code quality tools configuration"
}

function show_completion_info() {
    header "🎉 Site Created Successfully!"
    
    echo -e "${GREEN}Your new WordPress site is ready!${NC}"
    echo ""
    echo -e "${CYAN}📋 Site Information:${NC}"
    echo "• Site Name: $SITE_NAME"
    echo "• Description: $SITE_DESCRIPTION"
    echo "• WordPress Version: $WP_VERSION"
    echo "• PHP Version: $PHP_VERSION"
    echo ""
    echo -e "${CYAN}🌐 Access URLs:${NC}"
    echo "• Frontend: https://${SITE_NAME}.127.0.0.1.nip.io"
    echo "• Admin: https://${SITE_NAME}.127.0.0.1.nip.io/wp-admin"
    echo ""
    echo -e "${CYAN}🔐 Login Credentials:${NC}"
    echo "• Username: admin"
    echo "• Password: admin"
    echo ""
    echo -e "${CYAN}📁 File Locations:${NC}"
    echo "• WordPress Files: ./wordpress_${SITE_NAME}/"
    echo "• Nginx Config: ./config/nginx/${SITE_NAME}.conf"
    echo "• Logs: ./logs/wordpress_${SITE_NAME}/"
    echo ""
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo "• View logs: ./scripts/manage.sh logs wordpress_${SITE_NAME}"
    echo "• Run quality checks: ./scripts/manage.sh quality"
    echo "• Restart site: docker-compose restart wordpress_${SITE_NAME} nginx_${SITE_NAME}"
    echo ""
    echo -e "${YELLOW}💡 Next Steps:${NC}"
    echo "1. Visit your site to complete WordPress setup"
    echo "2. Install your themes and plugins"
    echo "3. Run code quality checks: ./scripts/manage.sh quality"
    echo "4. Start developing!"
    echo ""
}

# --- Main Execution ---
function main() {
    # Check if we're in the right directory
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "docker-compose.yml not found. Please run this script from the project root."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Prompt for site information
    prompt_for_site_info
    
    # Create the site
    echo ""
    header "🚀 Creating WordPress Site: $SITE_NAME"
    
    create_site_directory
    create_nginx_config
    update_env_file
    generate_docker_service
    create_database
    start_site
    setup_wordpress
    update_code_quality_tools
    
    echo ""
    show_completion_info
}

# Run main function
main "$@"