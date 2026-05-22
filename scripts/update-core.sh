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
    local failed=false
    validate_site_name "$site" || return 1

    if [[ "$FORCE" == true ]]; then
        FORCE_FLAG="--force"
    fi

    log_info "Updating WordPress core for: $site"

    # Check if WordPress container is running
    if ! $CONTAINER_RUNTIME ps --format "{{.Names}}" 2>/dev/null | grep -q "^wp_$site$"; then
        log_warning "Container for '$site' is not running, skipping..."
        return 1
    fi

    # Update core
    if run_wp_cli "$site" core update $FORCE_FLAG --quiet; then
        log_success "WordPress updated for: $site"
    else
        log_error "Failed to update: $site"
        failed=true
    fi

    # Update database
    log_info "Updating database for: $site"
    if run_wp_cli "$site" core update-db --quiet; then
        log_success "Database updated for: $site"
    else
        log_error "Failed to update database for: $site"
        failed=true
    fi

    if $failed; then
        return 1
    fi
}

# Main logic
if [[ "$UPDATE_ALL" == true ]]; then
    log_info "Updating WordPress core for all sites..."
    failed_count=0

    # Get all sites
    for site in $(get_sites); do
        update_site "$site" || failed_count=$((failed_count + 1))
        echo ""
    done

    if [[ "$failed_count" -gt 0 ]]; then
        log_error "$failed_count site(s) failed to update"
        exit 1
    fi
    log_success "All sites updated!"
else
    validate_site_name "$SITE_NAME" || exit 1
    if ! site_exists "$SITE_NAME"; then
        log_error "Site '$SITE_NAME' not found"
        exit 1
    fi
    update_site "$SITE_NAME"
fi
