#!/bin/bash
# Migration Script: From Complex to Simplified WordPress Platform

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
🔄 WordPress Platform Migration Tool

Usage: ./migrate-to-simple.sh [option]

Options:
  check             Check migration readiness
  backup            Backup existing data
  migrate           Perform full migration
  rollback          Rollback migration (if needed)

Examples:
  ./migrate-to-simple.sh check      # Check if ready to migrate
  ./migrate-to-simple.sh backup     # Backup before migration
  ./migrate-to-simple.sh migrate    # Full migration
EOF
}

# Check migration readiness
check_readiness() {
    log_info "Checking migration readiness..."
    
    local issues=()
    
    # Check if complex version exists
    if [[ ! -f "$PROJECT_ROOT/wp-dev" ]]; then
        issues+=("Complex version not found (wp-dev missing)")
    fi
    
    # Check if simplified files exist
    if [[ ! -f "$PROJECT_ROOT/wp-simple" ]]; then
        issues+=("Simplified version not found (wp-simple missing)")
    fi
    
    # Check for running containers
    if docker-compose ps | grep -q "Up"; then
        issues+=("Containers are running. Stop them first with './wp-dev stop'")
    fi
    
    # Check for existing simplified config
    if [[ -f "$PROJECT_ROOT/.env" ]] && [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        issues+=("Simplified configuration already exists. Remove or backup first.")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        log_success "Ready to migrate!"
        echo ""
        echo "Next steps:"
        echo "1. Run: ./migrate-to-simple.sh backup"
        echo "2. Run: ./migrate-to-simple.sh migrate"
        return 0
    else
        log_error "Migration blocked by the following issues:"
        for issue in "${issues[@]}"; do
            echo "  • $issue"
        done
        return 1
    fi
}

# Backup existing data
backup_data() {
    log_info "Creating backup of existing setup..."
    
    local backup_dir="$PROJECT_ROOT/backup-migration-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup configurations
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        cp "$PROJECT_ROOT/.env" "$backup_dir/"
    fi
    
    if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        cp "$PROJECT_ROOT/docker-compose.yml" "$backup_dir/"
    fi
    
    # Backup WordPress sites
    for wp_dir in "$PROJECT_ROOT"/wp_* "$PROJECT_ROOT"/wordpress_* "$PROJECT_ROOT"/xandar "$PROJECT_ROOT"/asgard; do
        if [[ -d "$wp_dir" ]]; then
            cp -r "$wp_dir" "$backup_dir/"
        fi
    done
    
    # Backup databases if possible
    if docker-compose ps db 2>/dev/null | grep -q "Up"; then
        log_info "Backing up databases..."
        docker-compose exec db mysqldump -u root -p"${MYSQL_ROOT_PASSWORD:-root}" --all-databases > "$backup_dir/databases.sql" 2>/dev/null || log_warning "Database backup failed"
    fi
    
    log_success "Backup created at: $backup_dir"
    echo "Backup contains: configurations, WordPress sites, and databases"
}

# Get WordPress sites from complex version
get_complex_sites() {
    local sites=()
    
    # Check for various site patterns
    if [[ -d "$PROJECT_ROOT/xandar" ]]; then
        sites+=("xandar")
    fi
    
    if [[ -d "$PROJECT_ROOT/asgard" ]]; then
        sites+=("asgard")
    fi
    
    for dir in "$PROJECT_ROOT"/wordpress_*; do
        if [[ -d "$dir" ]]; then
            sites+=("$(basename "$dir" | sed 's/^wordpress_//')")
        fi
    done
    
    printf '%s\n' "${sites[@]}"
}

# Perform migration
perform_migration() {
    log_info "Starting migration to simplified version..."
    
    # Get sites to migrate
    local sites=($(get_complex_sites))
    
    if [[ ${#sites[@]} -eq 0 ]]; then
        log_warning "No WordPress sites found to migrate"
    else
        log_info "Found sites to migrate: ${sites[*]}"
    fi
    
    # Setup simplified configuration
    log_info "Setting up simplified configuration..."
    
    # Backup existing files if they exist
    [[ -f "$PROJECT_ROOT/.env" ]] && mv "$PROJECT_ROOT/.env" "$PROJECT_ROOT/.env.backup"
    [[ -f "$PROJECT_ROOT/docker-compose.yml" ]] && mv "$PROJECT_ROOT/docker-compose.yml" "$PROJECT_ROOT/docker-compose.yml.backup"
    
    # Copy simplified files
    cp "$PROJECT_ROOT/.env.simple" "$PROJECT_ROOT/.env"
    cp "$PROJECT_ROOT/docker-compose.simple.yml" "$PROJECT_ROOT/docker-compose.yml"
    
    log_success "Configuration updated"
    
    # Start simplified environment
    log_info "Starting simplified environment..."
    chmod +x "$PROJECT_ROOT/wp-simple"
    
    # Start base services
    "$PROJECT_ROOT/wp-simple" start
    
    # Migrate WordPress sites
    local start_port=8001
    for site in "${sites[@]}"; do
        log_info "Migrating site: $site"
        
        # Create site using simplified tool
        "$PROJECT_ROOT/wp-simple" create "$site" &
        
        # Wait a moment for site creation
        sleep 5
        
        # Copy WordPress files if they exist in complex structure
        local complex_wp_dir=""
        local simple_wp_dir="$PROJECT_ROOT/wp_$site"
        
        # Find source directory
        if [[ -d "$PROJECT_ROOT/$site" ]]; then
            complex_wp_dir="$PROJECT_ROOT/$site"
        elif [[ -d "$PROJECT_ROOT/wordpress_$site" ]]; then
            complex_wp_dir="$PROJECT_ROOT/wordpress_$site"
        fi
        
        if [[ -n "$complex_wp_dir" && -d "$complex_wp_dir" ]]; then
            log_info "Copying WordPress files for $site..."
            # Copy custom themes, plugins, and uploads
            if [[ -d "$complex_wp_dir/wp-content" ]]; then
                cp -r "$complex_wp_dir/wp-content"/* "$simple_wp_dir/wp-content/" 2>/dev/null || true
            fi
            
            # Copy wp-config.php if it exists
            if [[ -f "$complex_wp_dir/wp-config.php" ]]; then
                cp "$complex_wp_dir/wp-config.php" "$simple_wp_dir/"
            fi
        fi
        
        log_success "Site $site migrated"
        start_port=$((start_port + 1))
    done
    
    # Wait for all sites to be created
    sleep 10
    
    log_success "Migration completed!"
    echo ""
    echo "What's next:"
    echo "1. Check site status: ./wp-simple list"
    echo "2. Access your sites at their URLs"
    echo "3. Run code quality checks: ./wp-simple check"
    echo ""
    echo "Complex version files are backed up with .backup extension"
    echo "Rollback with: ./migrate-to-simple.sh rollback"
}

# Rollback migration
rollback_migration() {
    log_warning "Rolling back migration..."
    
    # Restore configurations
    if [[ -f "$PROJECT_ROOT/.env.backup" ]]; then
        mv "$PROJECT_ROOT/.env.backup" "$PROJECT_ROOT/.env"
        log_success "Restored .env"
    fi
    
    if [[ -f "$PROJECT_ROOT/docker-compose.yml.backup" ]]; then
        mv "$PROJECT_ROOT/docker-compose.yml.backup" "$PROJECT_ROOT/docker-compose.yml"
        log_success "Restored docker-compose.yml"
    fi
    
    # Stop simplified environment
    if command -v "$PROJECT_ROOT/wp-simple" &>/dev/null; then
        "$PROJECT_ROOT/wp-simple" stop 2>/dev/null || true
    fi
    
    # Ask about removing simplified sites
    read -p "Remove simplified WordPress sites? [y/N]: " remove_sites
    if [[ "$remove_sites" =~ ^[Yy]$ ]]; then
        for site_dir in "$PROJECT_ROOT"/wp_*; do
            if [[ -d "$site_dir" ]]; then
                rm -rf "$site_dir"
                log_info "Removed $(basename "$site_dir")"
            fi
        done
    fi
    
    log_success "Rollback completed"
    echo "You can now use the complex version with './wp-dev start'"
}

# Main command dispatcher
main() {
    case "${1:-help}" in
        "check")
            check_readiness
            ;;
        "backup")
            backup_data
            ;;
        "migrate")
            if check_readiness; then
                perform_migration
            else
                log_error "Migration not ready. Fix issues first."
            fi
            ;;
        "rollback")
            rollback_migration
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"