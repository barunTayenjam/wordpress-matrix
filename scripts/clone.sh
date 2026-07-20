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

# Preserve or set stack marker
local_stack="nginx"
if [[ -f "$NEW_DIR/.matrix-stack" ]]; then
    local_stack=$(tr -d '[:space:]' < "$NEW_DIR/.matrix-stack")
elif [[ -f "$SOURCE_DIR/.matrix-stack" ]]; then
    local_stack=$(tr -d '[:space:]' < "$SOURCE_DIR/.matrix-stack")
fi
case "$local_stack" in
    apache|nginx) echo "$local_stack" > "$NEW_DIR/.matrix-stack" ;;
    *) echo "nginx" > "$NEW_DIR/.matrix-stack"; local_stack="nginx" ;;
esac

# Update wp-config.php
if [[ -f "$NEW_DIR/wp-config.php" ]]; then
    log_info "Updating configuration..."
    DB_NAME="${NEW_SITE}_db"
    sed -i.bak "s/${SOURCE_SITE}_db/$DB_NAME/g" "$NEW_DIR/wp-config.php"
    rm "$NEW_DIR/wp-config.php.bak"
fi

# Create database
log_info "Creating database..."
if ! create_database "$NEW_SITE"; then
    log_error "Failed to create database for '$NEW_SITE'"
    exit 1
fi

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

# Search and replace URLs in database (use HOST_IP so LAN devices resolve correctly)
OLD_URL="http://${HOST_IP}:$(get_site_port "$SOURCE_SITE")"
NEW_PORT="$(get_next_port)"
NEW_URL="http://${HOST_IP}:$NEW_PORT"
# Also cover legacy localhost-based source URLs in the cloned DB.
LEGACY_OLD_URL="http://localhost:$(get_site_port "$SOURCE_SITE")"

log_info "Updating URLs in database..."
if ! run_wp_cli "$NEW_SITE" search-replace "$OLD_URL" "$NEW_URL" --skip-plugins --skip-themes --quiet; then
    log_error "Failed to search-replace '$OLD_URL' -> '$NEW_URL'"
    exit 1
fi
# Best-effort cleanup of any legacy localhost URLs carried over from the source.
if [[ "$LEGACY_OLD_URL" != "$OLD_URL" ]]; then
    run_wp_cli "$NEW_SITE" search-replace "$LEGACY_OLD_URL" "$NEW_URL" --skip-plugins --skip-themes --quiet 2>/dev/null || true
fi

# Update docker-compose.yml (inherit stack from source)
log_info "Updating docker-compose configuration..."
if [[ "$local_stack" == "apache" ]]; then
    local php_version
    php_version=$(get_site_php_version_from_compose "$SOURCE_SITE")
    [[ -z "$php_version" ]] && php_version="${DEFAULT_PHP_VERSION:-8.3}"
    compose_add_site "$NEW_SITE" "$php_version" "$NEW_PORT" "" "apache"
    matrix_site_build_if_apache "$NEW_SITE"
else
    create_nginx_config "$NEW_SITE"
    update_compose_file "$NEW_SITE" "$NEW_PORT"
fi

log_info "Starting cloned site..."
matrix_site_up "$NEW_SITE"

log_success "Site cloned successfully!"
log_info "Access: $NEW_URL"
