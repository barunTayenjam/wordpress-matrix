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

# Execute a WP-CLI command.
function wp_cli() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        error "Invalid command."
        echo "Usage: $0 wp <site> <command>"
        echo "Example: $0 wp wordpress1 plugin list"
        exit 1
    fi

    site=$1
    shift
    wp_command_and_args=("$@")

    echo "🤖  Running WP-CLI command on '$site': wp ${wp_command_and_args[@]}"
    docker-compose exec wpcli wp "${wp_command_and_args[@]}" --path=/var/www/html/$site
}

# Run PHP Code Sniffer
function lint_php() {
    echo "🧹  Running PHP Code Sniffer..."
    docker-compose run --rm phpcs --standard=/phpcs-config/phpcs.xml /app
    success "PHP Code Sniffer finished."
}

# Run PHPStan static analysis
function analyse_php() {
    echo "🔍  Running PHPStan static analysis..."
    docker-compose run --rm phpstan analyse /app --configuration=/phpstan-config/phpstan.neon
    success "PHPStan analysis finished."
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
    wp)
        wp_cli "$2" "${@:3}"
        ;;
    lint)
        lint_php
        ;;
    analyse)
        analyse_php
        ;;
    composer)
        composer_cmd "${@:2}"
        ;;
    npm)
        npm_cmd "${@:2}"
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|wp|lint|analyse|composer|npm|backup|restore}"
        exit 1
        ;;
esac

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

# Execute a WP-CLI command.
function wp_cli() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        error "Invalid command."
        echo "Usage: $0 wp <site> <command>"
        echo "Example: $0 wp wordpress1 plugin list"
        exit 1
    fi

    site=$1
    shift
    wp_command_and_args=("$@")

    echo "🤖  Running WP-CLI command on '$site': wp ${wp_command_and_args[@]}"
    docker-compose exec wpcli wp "${wp_command_and_args[@]}" --path=/var/www/html/$site
}

# Run PHP Code Sniffer
function lint_php() {
    echo "🧹  Running PHP Code Sniffer..."
    docker-compose run --rm phpcs --standard=/phpcs-config/phpcs.xml /app
    success "PHP Code Sniffer finished."
}

# Run PHPStan static analysis
function analyse_php() {
    echo "🔍  Running PHPStan static analysis..."
    docker-compose run --rm phpstan analyse /app --configuration=/phpstan-config/phpstan.neon
    success "PHPStan analysis finished."
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
    wp)
        wp_cli "$2" "${@:3}"
        ;;
    lint)
        lint_php
        ;;
    analyse)
        analyse_php
        ;;
    composer)
        composer_cmd "${@:2}"
        ;;
    npm)
        npm_cmd "${@:2}"
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|wp|lint|analyse|composer|npm|backup|restore}"
        exit 1
        ;;
esac
