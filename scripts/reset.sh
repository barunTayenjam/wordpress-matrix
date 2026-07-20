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
validate_site_name "$SITE_NAME" || exit 1

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
if ! read -r -p "Continue? [y/N]: " confirm; then
    log_info "Cancelled"
    exit 0
fi
confirm="${confirm:-}"

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
if ! $CONTAINER_RUNTIME exec -e MYSQL_PWD="${MYSQL_PASSWORD:-wp_password}" wp_db mysqldump --no-tablespaces -u"${MYSQL_USER:-wp_user}" "$DB_NAME" \
        > "$BACKUP_DIR/database.sql"; then
    log_error "Failed to export database for '$SITE_NAME'"
    exit 1
fi

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
$CONTAINER_RUNTIME exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-root}" wp_db mysql -u root -e \
    "DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '${MYSQL_USER:-wp_user}'@'%'; FLUSH PRIVILEGES;"

# Restore wp-content if needed
if [[ "$KEEP_PLUGINS" == true ]] || [[ "$KEEP_THEMES" == true ]] || [[ "$KEEP_UPLOADS" == true ]]; then
    log_info "Restoring wp-content..."
    SITE_DIR="$PROJECT_ROOT/wp_$SITE_NAME"

    # Copy to a temp sibling then move into place so a failure never leaves the
    # target directory missing its plugins/themes/uploads.
    restore_dir() {
        local src="$1"
        local dest_parent="$2"
        local name
        name=$(basename "$src")
        local staging="$dest_parent/.${name}.restoring.$$"
        if ! cp -R "$src" "$staging"; then
            log_error "Failed to restore $name"
            rm -rf "$staging"
            return 1
        fi
        rm -rf "$dest_parent/$name"
        mv "$staging" "$dest_parent/$name"
    }

    [[ "$KEEP_PLUGINS" == true ]] && { restore_dir "$BACKUP_CONTENT_DIR/plugins" "$SITE_DIR/wp-content" || exit 1; }
    [[ "$KEEP_THEMES" == true ]]  && { restore_dir "$BACKUP_CONTENT_DIR/themes"  "$SITE_DIR/wp-content" || exit 1; }
    [[ "$KEEP_UPLOADS" == true ]] && { restore_dir "$BACKUP_CONTENT_DIR/uploads" "$SITE_DIR/wp-content" || exit 1; }
fi

# WordPress will be reinstalled on first visit or via wp-cli
log_success "Site '$SITE_NAME' reset successfully!"
log_info "Backup saved to: $BACKUP_DIR"
log_info "Visit the site to complete WordPress installation"
