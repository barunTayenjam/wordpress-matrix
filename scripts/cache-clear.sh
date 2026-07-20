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
    log_info "  --wp-only          Clear only WordPress object cache + Super Cache disk cache"
    log_info "  --supercache-only  Clear only WP Super Cache disk cache"
    exit 1
}

REDIS_ONLY=false
WP_ONLY=false
SUPERCACHE_ONLY=false
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
        --supercache-only)
            SUPERCACHE_ONLY=true
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
    if $CONTAINER_RUNTIME exec wp_redis redis-cli FLUSHALL > /dev/null 2>&1; then
        log_success "Redis cache cleared"
    else
        log_error "Failed to clear Redis cache"
    fi
}

# Clear WordPress object cache
clear_wp_cache() {
    local site="$1"
    validate_site_name "$site" || return 1
    log_info "Clearing WordPress object cache for: $site"

    if run_wp_cli "$site" cache flush --quiet; then
        log_success "WordPress object cache cleared for: $site"
    else
        log_warning "Failed to clear WordPress object cache for: $site (may not have object cache)"
    fi
}

# Clear WP Super Cache disk cache
clear_supercache() {
    local site="$1"
    validate_site_name "$site" || return 1
    log_info "Clearing WP Super Cache disk cache for: $site"

    if run_wp_cli "$site" super-cache flush --quiet 2>/dev/null; then
        log_success "WP Super Cache disk cache cleared for: $site"
    else
        log_warning "WP Super Cache not active for: $site — skipping disk cache flush"
    fi
}

# Main logic
if [[ "$REDIS_ONLY" == false ]]; then
    if [[ "$CLEAR_ALL" == true ]]; then
        log_info "Clearing caches for all sites..."
        for site in $(get_sites); do
            if [[ "$SUPERCACHE_ONLY" == false ]]; then
                clear_wp_cache "$site"
            fi
            clear_supercache "$site"
        done
    else
        validate_site_name "$SITE_NAME" || exit 1
        if ! site_exists "$SITE_NAME"; then
            log_error "Site '$SITE_NAME' not found"
            exit 1
        fi
        if [[ "$SUPERCACHE_ONLY" == false ]]; then
            clear_wp_cache "$SITE_NAME"
        fi
        clear_supercache "$SITE_NAME"
    fi
fi

if [[ "$WP_ONLY" == false && "$SUPERCACHE_ONLY" == false ]]; then
    clear_redis
fi

log_success "Cache clear complete!"
