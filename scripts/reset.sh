#!/bin/bash
# Reset a WordPress site to fresh install

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

usage() {
    log_info "Usage: ./reset.sh <site-name> [--keep-plugins]"
    log_info "Options:"
    log_info "  --keep-plugins    Keep installed plugins"
    log_info "  --keep-themes      Keep installed themes"
    log_info "  --keep-uploads      Keep uploaded files"
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

SITE_NAME="$1"
KEEP_PLUGINS=false
KEEP_THEMES=false
KEEP_UPLOADS=false

# Parse options
shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --keep-plugins)
            KEEP_PLUGINS=true
            shift
            ;;
        --keep-themes)
            KEEP_THEMES=true
            shift
            ;;
        --keep-uploads)
            KEEP_UPLOADS=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

if ! site_exists "$SITE_NAME"; then
    log_error "Site '$SITE_NAME' not found"
    exit 1
fi

log_warning "This will RESET site '$SITE_NAME' to fresh WordPress install"
read -p "Continue? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

log_info "Resetting '$SITE_NAME'..."

# Backup current state first
BACKUP_DIR="$PROJECT_ROOT/backups/reset_$(date +%Y%m%d_%H%M%S)_$SITE_NAME"
mkdir -p "$BACKUP_DIR"
log_info "Backing up to: $BACKUP_DIR"

# Export database
DB_NAME="${SITE_NAME}_db"
$DOCKER_COMPOSE exec -T db mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "$DB_NAME" \
    > "$BACKUP_DIR/database.sql"

# Backup wp-content
if [[ "$KEEP_PLUGINS" == true ]] || [[ "$KEEP_THEMES" == true ]] || [[ "$KEEP_UPLOADS" == true ]]; then
    BACKUP_CONTENT_DIR="$BACKUP_DIR/wp-content"
    mkdir -p "$BACKUP_CONTENT_DIR"

    SITE_DIR="$PROJECT_ROOT/wp_$SITE_NAME"
    [[ "$KEEP_PLUGINS" == true ]] && cp -R "$SITE_DIR/wp-content/plugins" "$BACKUP_CONTENT_DIR/"
    [[ "$KEEP_THEMES" == true ]] && cp -R "$SITE_DIR/wp-content/themes" "$BACKUP_CONTENT_DIR/"
    [[ "$KEEP_UPLOADS" == true ]] && cp -R "$SITE_DIR/wp-content/uploads" "$BACKUP_CONTENT_DIR/"
fi

# Drop and recreate database
log_info "Resetting database..."
$DOCKER_COMPOSE exec db mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e \
    "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Restore wp-content if needed
if [[ "$KEEP_PLUGINS" == true ]] || [[ "$KEEP_THEMES" == true ]] || [[ "$KEEP_UPLOADS" == true ]]; then
    log_info "Restoring wp-content..."
    SITE_DIR="$PROJECT_ROOT/wp_$SITE_NAME"

    [[ "$KEEP_PLUGINS" == true ]] && rm -rf "$SITE_DIR/wp-content/plugins" && cp -R "$BACKUP_CONTENT_DIR/plugins" "$SITE_DIR/wp-content/"
    [[ "$KEEP_THEMES" == true ]] && rm -rf "$SITE_DIR/wp-content/themes" && cp -R "$BACKUP_CONTENT_DIR/themes" "$SITE_DIR/wp-content/"
    [[ "$KEEP_UPLOADS" == true ]] && rm -rf "$SITE_DIR/wp-content/uploads" && cp -R "$BACKUP_CONTENT_DIR/uploads" "$SITE_DIR/wp-content/"
fi

# WordPress will be reinstalled on first visit or via wp-cli
log_success "Site '$SITE_NAME' reset successfully!"
log_info "Backup saved to: $BACKUP_DIR"
log_info "Visit the site to complete WordPress installation"
