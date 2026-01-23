#!/bin/bash
# Backup all sites (database + files)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

usage() {
    log_info "Usage: ./backup.sh [site-name] [--all]"
    log_info "Options:"
    log_info "  --all              Backup all sites"
    log_info "  --db-only          Backup only databases"
    log_info "  --files-only       Backup only files"
    log_info "  --compress         Compress backups"
    exit 1
}

BACKUP_ALL=false
DB_ONLY=false
FILES_ONLY=false
COMPRESS=false

if [[ $# -eq 0 ]]; then
    log_error "Site name or --all required"
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            BACKUP_ALL=true
            shift
            ;;
        --db-only)
            DB_ONLY=true
            shift
            ;;
        --files-only)
            FILES_ONLY=true
            shift
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            SITE_NAME="$1"
            shift
            ;;
    esac
done

# Create backup directory
BACKUP_DIR="$PROJECT_ROOT/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup single site
backup_site() {
    local site="$1"
    local site_backup_dir="$BACKUP_DIR/$site"
    mkdir -p "$site_backup_dir"

    log_info "Backing up: $site"

    # Backup database
    if [[ "$FILES_ONLY" == false ]]; then
        DB_NAME="${site}_db"
        local db_backup="$site_backup_dir/database.sql"

        log_info "  Exporting database..."
        $DOCKER_COMPOSE exec -T db mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
            --single-transaction --quick --lock-tables=false "$DB_NAME" > "$db_backup"

        if [[ $? -eq 0 ]]; then
            local size=$(du -h "$db_backup" | cut -f1)
            log_success "  Database backed up ($size)"
        else
            log_error "  Failed to backup database"
            return 1
        fi
    fi

    # Backup files
    if [[ "$DB_ONLY" == false ]]; then
        local site_dir="$PROJECT_ROOT/wp_$site"
        local files_backup="$site_backup_dir/files"

        log_info "  Backing up files..."
        cp -R "$site_dir/wp-content" "$files_backup"

        if [[ $? -eq 0 ]]; then
            local size=$(du -sh "$files_backup" | cut -f1)
            log_success "  Files backed up ($size)"
        else
            log_error "  Failed to backup files"
            return 1
        fi
    fi
}

# Main logic
if [[ "$BACKUP_ALL" == true ]]; then
    log_info "Backing up all sites..."

    site_count=0
    for site in $(get_sites); do
        backup_site "$site"
        ((site_count++))
        echo ""
    done

    log_success "All $site_count sites backed up to: $BACKUP_DIR"
else
    if [[ -z "${SITE_NAME:-}" ]]; then
        log_error "Site name required when not using --all"
        usage
    fi
    if ! site_exists "$SITE_NAME"; then
        log_error "Site '$SITE_NAME' not found"
        exit 1
    fi
    backup_site "$SITE_NAME"
    log_success "Site '$SITE_NAME' backed up to: $BACKUP_DIR/$SITE_NAME"
fi

# Compress if requested
if [[ "$COMPRESS" == true ]]; then
    log_info "Compressing backups..."
    local compressed_file="$BACKUP_DIR.tar.gz"

    if tar -czf "$compressed_file" -C "$PROJECT_ROOT/backups" "$(basename "$BACKUP_DIR")" 2>/dev/null; then
        local size=$(du -h "$compressed_file" | cut -f1)
        log_success "Backup compressed: $compressed_file ($size)"

        # Remove uncompressed backup
        rm -rf "$BACKUP_DIR"
    else
        log_error "Failed to compress backup"
    fi
fi

log_info "Backup location: $BACKUP_DIR"
