#!/bin/bash
# Clear all caches (Redis and WordPress)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

usage() {
    log_info "Usage: ./cache-clear.sh [site-name] [--all]"
    log_info "Options:"
    log_info "  --all              Clear cache for all sites"
    log_info "  --redis-only       Clear only Redis cache"
    log_info "  --wp-only          Clear only WordPress object cache"
    exit 1
}

REDIS_ONLY=false
WP_ONLY=false
CLEAR_ALL=false

if [[ $# -eq 0 ]]; then
    log_error "Site name or --all required"
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            CLEAR_ALL=true
            shift
            ;;
        --redis-only)
            REDIS_ONLY=true
            shift
            ;;
        --wp-only)
            WP_ONLY=true
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

# Clear Redis cache
clear_redis() {
    log_info "Clearing Redis cache..."
    if $DOCKER_COMPOSE exec -T redis redis-cli FLUSHALL > /dev/null 2>&1; then
        log_success "Redis cache cleared"
    else
        log_error "Failed to clear Redis cache"
    fi
}

# Clear WordPress object cache
clear_wp_cache() {
    local site="$1"
    log_info "Clearing WordPress cache for: $site"

    if $DOCKER_COMPOSE exec -T wpcli wp cache flush --path="/var/www/html/$site" --quiet; then
        log_success "WordPress cache cleared for: $site"
    else
        log_warning "Failed to clear WordPress cache for: $site (may not have object cache)"
    fi
}

# Main logic
if [[ "$REDIS_ONLY" == false ]]; then
    if [[ "$CLEAR_ALL" == true ]]; then
        log_info "Clearing caches for all sites..."
        for site in $(get_sites); do
            clear_wp_cache "$site"
        done
    else
        if ! site_exists "$SITE_NAME"; then
            log_error "Site '$SITE_NAME' not found"
            exit 1
        fi
        clear_wp_cache "$SITE_NAME"
    fi
fi

if [[ "$WP_ONLY" == false ]]; then
    clear_redis
fi

log_success "Cache clear complete!"
