#!/bin/bash
# Database search and replace

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

usage() {
    log_info "Usage: ./search-replace.sh <site-name> <search> <replace> [--dry-run]"
    log_info "Examples:"
    log_info "  ./search-replace.sh mysite \"http://dev.local\" \"https://production.com\""
    log_info "  ./search-replace.sh mysite \"dev.local\" \"production.com\" --dry-run"
    log_info "  ./search-replace.sh mysite \"old-domain.com\" \"new-domain.com\" --precise"
    exit 1
}

if [[ $# -lt 3 ]]; then
    usage
fi

SITE_NAME="$1"
SEARCH="$2"
REPLACE="$3"
DRY_RUN=false
PRECISE=false

# Parse options
shift 3
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --precise)
            PRECISE=true
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

log_info "Search and replace for: $SITE_NAME"
log_info "Search: $SEARCH"
log_info "Replace: $REPLACE"

# Build wp-cli command
CMD="$DOCKER_COMPOSE exec -T wpcli wp search-replace \"$SEARCH\" \"$REPLACE\" --path=\"/var/www/html/$SITE_NAME\" --skip-plugins --skip-themes --quiet"

if [[ "$PRECISE" == true ]]; then
    CMD="$CMD --precise"
fi

if [[ "$DRY_RUN" == true ]]; then
    CMD="$CMD --dry-run"
    log_warning "DRY RUN MODE - No changes will be made"
fi

log_info "Running search and replace..."

# Execute and show results
if eval "$CMD"; then
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Dry run complete. Review the changes above."
    else
        log_success "Search and replace completed!"
    fi
else
    log_error "Search and replace failed"
    exit 1
fi
