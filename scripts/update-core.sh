#!/bin/bash
# Update WordPress core for specific site or all sites

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

usage() {
    log_info "Usage: ./update-core.sh [site-name] [--all]"
    log_info "Examples:"
    log_info "  ./update-core.sh mysite"
    log_info "  ./update-core.sh --all"
    log_info "  ./update-core.sh --all --force"
    exit 1
}

FORCE=false
UPDATE_ALL=false

if [[ $# -lt 1 ]]; then
    log_error "Site name or --all required"
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            UPDATE_ALL=true
            shift
            ;;
        --force)
            FORCE=true
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

# Function to update single site
update_site() {
    local site="$1"
    local FORCE_FLAG=""

    if [[ "$FORCE" == true ]]; then
        FORCE_FLAG="--force"
    fi

    log_info "Updating WordPress core for: $site"

    # Check if WordPress container is running
    if ! $DOCKER_COMPOSE ps | grep -q "wp_$site.*Up"; then
        log_warning "Container for '$site' is not running, skipping..."
        return
    fi

    # Update core
    if $DOCKER_COMPOSE exec -T wpcli wp core update --path="/var/www/html/$site" $FORCE_FLAG --quiet; then
        log_success "WordPress updated for: $site"
    else
        log_error "Failed to update: $site"
    fi

    # Update database
    log_info "Updating database for: $site"
    if $DOCKER_COMPOSE exec -T wpcli wp core update-db --path="/var/www/html/$site" --quiet; then
        log_success "Database updated for: $site"
    else
        log_error "Failed to update database for: $site"
    fi
}

# Main logic
if [[ "$UPDATE_ALL" == true ]]; then
    log_info "Updating WordPress core for all sites..."

    # Get all sites
    for site in $(get_sites); do
        update_site "$site"
        echo ""
    done

    log_success "All sites updated!"
else
    if ! site_exists "$SITE_NAME"; then
        log_error "Site '$SITE_NAME' not found"
        exit 1
    fi
    update_site "$SITE_NAME"
fi
