#!/bin/bash

# A unified script for managing the WordPress development environment.

set -e

# --- Configuration ---

# Services to check for health.
# Add any critical services that have a health check defined in docker-compose.yml.
HEALTH_CHECK_SERVICES=("db-primary" "nginx-wp1" "nginx-wp2")

# Time to wait for services to become healthy (in seconds).
HEALTH_CHECK_TIMEOUT=600

# --- Helper Functions ---

# Echo a message with a green checkmark.
function success() {
    echo -e "✅  \033[1;32m$1\033[0m"
}

# Echo a message with a red cross.
function error() {
    echo -e "❌  \033[1;31m$1\033[0m"
}

# Echo a message with a yellow warning sign.
function warning() {
    echo -e "⚠️  \033[1;33m$1\033[0m"
}

# --- Command Functions ---

# Start the environment and check the health of critical services.
function start_env() {
    echo "🚀  Starting the WordPress environment..."
    docker-compose up -d

    echo "
🔍  Verifying the health of critical services..."
    for service in "${HEALTH_CHECK_SERVICES[@]}"; do
        echo -n "    - Waiting for '$service' to be healthy... "
        
        end_time=$((SECONDS + HEALTH_CHECK_TIMEOUT))
        while [ $SECONDS -lt $end_time ]; do
            status=$(docker-compose ps -q $service | xargs docker inspect -f '{{.State.Health.Status}}')
            if [ "$status" == "healthy" ]; then
                echo -e "\033[1;32mHealthy\033[0m"
                break
            fi
            sleep 2
        done

        if [ "$status" != "healthy" ]; then
            error "'$service' did not become healthy in time."
            echo "    - Check the logs with: docker-compose logs $service"
            exit 1
        fi
    done

    success "Environment is up and running!"

    echo "
🌐  Access your services at:"
    echo "    - WordPress 1: https://wordpress1.${DOMAIN_SUFFIX}"
    echo "    - WordPress 2: https://wordpress2.${DOMAIN_SUFFIX}"
    echo "    - phpMyAdmin:  https://phpmyadmin.${DOMAIN_SUFFIX}"
    echo "    - MailHog:     https://mailhog.${DOMAIN_SUFFIX}"
}

# Stop the environment.
function stop_env() {
    echo "🛑  Stopping the WordPress environment..."
    docker-compose down
    success "Environment has been stopped."
}

# Restart the environment.
function restart_env() {
    stop_env
    start_env
}

# Show the status of the environment.
function status_env() {
    echo "📊  Current status of the environment:"
    docker-compose ps
}

# Tail the logs of a specific service.
function logs_env() {
    if [ -z "$1" ]; then
        error "Please specify a service to view the logs for."
        echo "Usage: $0 logs <service-name>"
        exit 1
    fi
    echo "📋  Tailing logs for '$1'. Press Ctrl+C to exit."
    docker-compose logs -f "$1"
}



# =============================================================================
# CODE QUALITY FUNCTIONS
# =============================================================================

# Run PHP Code Sniffer
function lint_php() {
    echo "🧹  Running PHP Code Sniffer (WordPress Coding Standards)..."
    docker-compose run --rm phpcs phpcs --standard=/phpcs-config/phpcs.xml --report=full --report-file=/tmp/phpcs-report.txt
    success "PHP Code Sniffer finished."
}

# Fix PHP Code Sniffer issues automatically
function fix_php() {
    echo "🔧  Auto-fixing PHP Code Sniffer issues..."
    docker-compose run --rm phpcs phpcbf --standard=/phpcs-config/phpcs.xml
    success "PHP Code Beautifier and Fixer finished."
}

# Run PHPStan static analysis (Level 9)
function analyse_php() {
    echo "🔍  Running PHPStan static analysis (Level 9)..."
    docker-compose run --rm phpstan analyse --configuration=/phpstan-config/phpstan.neon --memory-limit=1G
    success "PHPStan analysis finished."
}

# Run PHP Mess Detector
function mess_detector() {
    echo "🔍  Running PHP Mess Detector..."
    docker-compose run --rm phpmd phpmd /app/wordpress1/wp-content/themes,/app/wordpress1/wp-content/plugins,/app/wordpress2/wp-content/themes,/app/wordpress2/wp-content/plugins text /phpmd-config/phpmd.xml
    success "PHP Mess Detector finished."
}

# Run Psalm static analysis
function psalm_analysis() {
    echo "🔍  Running Psalm static analysis..."
    docker-compose run --rm psalm psalm --config=/psalm-config/psalm.xml --show-info=true
    success "Psalm analysis finished."
}

# Run PHPUnit tests
function test_php() {
    echo "🧪  Running PHPUnit tests..."
    docker-compose run --rm phpunit phpunit --configuration=/phpunit-config/phpunit.xml --coverage-html=/app/tests/coverage/html
    success "PHPUnit tests finished."
}

# Run all code quality checks
function quality_check() {
    echo "🎯  Running comprehensive code quality checks..."
    echo ""
    
    echo "📋  Step 1/5: PHP Code Sniffer (Coding Standards)"
    lint_php
    echo ""
    
    echo "📋  Step 2/5: PHPStan (Static Analysis Level 9)"
    analyse_php
    echo ""
    
    echo "📋  Step 3/5: PHP Mess Detector (Code Quality)"
    mess_detector
    echo ""
    
    echo "📋  Step 4/5: Psalm (Advanced Static Analysis)"
    psalm_analysis
    echo ""
    
    echo "📋  Step 5/5: PHPUnit (Unit Tests)"
    test_php
    echo ""
    
    success "🎉  All code quality checks completed!"
    echo ""
    echo "📊  Reports available at:"
    echo "   - PHPCS: Check console output above"
    echo "   - PHPStan: Check console output above"
    echo "   - PHPMD: Check console output above"
    echo "   - Psalm: Check console output above"
    echo "   - PHPUnit: ./logs/phpunit/ and ./tests/coverage/"
}

# Quick code quality check (essential tools only)
function quick_check() {
    echo "⚡  Running quick code quality check..."
    echo ""
    
    echo "📋  Step 1/2: PHP Code Sniffer"
    lint_php
    echo ""
    
    echo "📋  Step 2/2: PHPStan Level 9"
    analyse_php
    echo ""
    
    success "⚡  Quick quality check completed!"
}

# Run Composer commands
function composer_cmd() {
    if [ -z "$1" ]; then
        error "Please provide a Composer command."
        echo "Usage: $0 composer <command>"
        exit 1
    fi
    echo "📦  Running Composer command: composer $@"
    docker-compose run --rm composer "$@"
    success "Composer command finished."
}

# Run NPM commands
function npm_cmd() {
    if [ -z "$1" ]; then
        error "Please provide an NPM command."
        echo "Usage: $0 npm <command>"
        exit 1
    fi
    echo "🌐  Running NPM command: npm $@"
    docker-compose run --rm node npm "$@"
    success "NPM command finished."
}

# Backup the database
function backup_db() {
    echo "💾  Backing up the database..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="/var/lib/mysql_backup/backup_${TIMESTAMP}.sql"
    docker-compose exec db-primary sh -c "mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --all-databases > ${BACKUP_FILE}"
    success "Database backup created at ${BACKUP_FILE} inside the db-primary container."
}

# Restore the database
function restore_db() {
    if [ -z "$1" ]; then
        error "Please specify a backup file to restore from."
        echo "Usage: $0 restore <backup-file-path>"
        echo "Example: $0 restore /var/lib/mysql_backup/backup_20231027_123456.sql"
        exit 1
    fi
    BACKUP_FILE="$1"
    echo "💿  Restoring database from ${BACKUP_FILE}..."
    docker-compose exec db-primary sh -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} < ${BACKUP_FILE}"
    success "Database restored from ${BACKUP_FILE}."
}

# --- Main Script ---

case "$1" in
    start)
        start_env
        ;;
    stop)
        stop_env
        ;;
    restart)
        restart_env
        ;;
    status)
        status_env
        ;;
    logs)
        logs_env "$2"
        ;;
    
    # Code Quality Commands
    lint)
        lint_php
        ;;
    fix)
        fix_php
        ;;
    analyse)
        analyse_php
        ;;
    phpmd)
        mess_detector
        ;;
    psalm)
        psalm_analysis
        ;;
    test)
        test_php
        ;;
    quality)
        quality_check
        ;;
    quick-check)
        quick_check
        ;;
    
    # Development Tools
    composer)
        composer_cmd "${@:2}"
        ;;
    npm)
        npm_cmd "${@:2}"
        ;;
    
    # Site Management
    create-site)
        ./scripts/create-site.sh
        ;;
    list-sites)
        ./scripts/manage-sites.sh list
        ;;
    site-info)
        if [ -z "$2" ]; then
            error "Please specify a site name"
            echo "Usage: $0 site-info <site-name>"
            exit 1
        fi
        ./scripts/manage-sites.sh info "$2"
        ;;
    
    # Database Management
    backup)
        backup_db
        ;;
    restore)
        restore_db
        ;;
    *)
        echo "🎯  Ultimate WordPress Development Matrix - Management Script"
        echo ""
        echo "📋  Environment Management:"
        echo "   start          - Start the development environment"
        echo "   stop           - Stop the development environment"
        echo "   restart        - Restart the development environment"
        echo "   status         - Show status of all services"
        echo "   logs [service] - Show logs for a service"
        echo ""
        echo "🌐  Site Management:"
        echo "   create-site    - Create a new WordPress development site"
        echo "   list-sites     - List all WordPress sites"
        echo "   site-info      - Show information about a specific site"
        echo ""
        echo "🔍  Code Quality Tools:"
        echo "   lint           - Run PHP Code Sniffer (WordPress Standards)"
        echo "   fix            - Auto-fix PHP Code Sniffer issues"
        echo "   analyse        - Run PHPStan static analysis (Level 9)"
        echo "   phpmd          - Run PHP Mess Detector"
        echo "   psalm          - Run Psalm static analysis"
        echo "   test           - Run PHPUnit tests"
        echo "   quality        - Run all code quality checks"
        echo "   quick-check    - Run essential quality checks only"
        echo ""
        echo "🛠️  Development Tools:"
        echo "   composer <cmd> - Run Composer commands"
        echo "   npm <cmd>      - Run NPM commands"
        echo ""
        echo "💾  Database Management:"
        echo "   backup         - Backup the database"
        echo "   restore        - Restore the database"
        echo ""
        echo "Example usage:"
        echo "   $0 start"
        echo "   $0 create-site"
        echo "   $0 list-sites"
        echo "   $0 quality"
        echo "   $0 composer install"
        echo "   $0 npm install"
        echo ""
        echo "🚀  Quick Start:"
        echo "   1. $0 start              # Start the environment"
        echo "   2. $0 create-site        # Create your first site"
        echo "   3. $0 quality            # Run code quality checks"
        exit 1
        ;;
esac
