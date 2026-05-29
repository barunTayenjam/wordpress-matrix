#!/bin/bash
# Clone an existing WordPress site to create a new one

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

# Usage
usage() {
    log_info "Usage: ./clone.sh <source-site> <new-site-name>"
    log_info "Example: ./clone.sh mysite mysite-copy"
    exit 1
}

# Check arguments
if [[ $# -lt 2 ]]; then
    usage
fi

SOURCE_SITE="$1"
NEW_SITE="$2"

validate_site_name "$SOURCE_SITE" || exit 1
validate_site_name "$NEW_SITE" || exit 1

# Validate source site exists
if ! site_exists "$SOURCE_SITE"; then
    log_error "Source site '$SOURCE_SITE' not found"
    exit 1
fi

# Validate new site doesn't exist
if site_exists "$NEW_SITE"; then
    log_error "Target site '$NEW_SITE' already exists"
    exit 1
fi

log_info "Cloning '$SOURCE_SITE' to '$NEW_SITE'..."

# Create new site directory
SOURCE_DIR="$PROJECT_ROOT/wp_$SOURCE_SITE"
NEW_DIR="$PROJECT_ROOT/wp_$NEW_SITE"

log_info "Copying files..."
cp -R "$SOURCE_DIR" "$NEW_DIR"

# Update wp-config.php
if [[ -f "$NEW_DIR/wp-config.php" ]]; then
    log_info "Updating configuration..."
    DB_NAME="${NEW_SITE}_db"
    sed -i.bak "s/${SOURCE_SITE}_db/$DB_NAME/g" "$NEW_DIR/wp-config.php"
    rm "$NEW_DIR/wp-config.php.bak"
fi

# Create database
log_info "Creating database..."
create_database "$NEW_SITE"

# Import database
log_info "Importing database..."
DB_DUMP=$(mktemp)
if ! $CONTAINER_RUNTIME exec -e MYSQL_PWD="${MYSQL_PASSWORD:-wp_password}" wp_db mysqldump --no-tablespaces -u"${MYSQL_USER:-wp_user}" "${SOURCE_SITE}_db" > "$DB_DUMP"; then
    rm -f "$DB_DUMP"
    log_error "Failed to export source database"
    exit 1
fi
if ! $CONTAINER_RUNTIME exec -i -e MYSQL_PWD="${MYSQL_PASSWORD:-wp_password}" wp_db mysql -u"${MYSQL_USER:-wp_user}" "${NEW_SITE}_db" < "$DB_DUMP"; then
    rm -f "$DB_DUMP"
    log_error "Failed to import target database"
    exit 1
fi
rm -f "$DB_DUMP"

# Search and replace URLs in database
OLD_URL="http://localhost:$(get_site_port "$SOURCE_SITE")"
NEW_PORT="$(get_next_port)"
NEW_URL="http://localhost:$NEW_PORT"

log_info "Updating URLs in database..."
run_wp_cli "$NEW_SITE" search-replace "$OLD_URL" "$NEW_URL" --skip-plugins --skip-themes --quiet

# Create nginx config
create_nginx_config "$NEW_SITE"

# Update docker-compose.yml
log_info "Updating docker-compose configuration..."
update_compose_file "$NEW_SITE" "$NEW_PORT"

log_info "Starting cloned site..."
$DOCKER_COMPOSE up -d "wp_$NEW_SITE" "nginx_$NEW_SITE" 2>/dev/null || true

log_success "Site cloned successfully!"
log_info "Access: $NEW_URL"
