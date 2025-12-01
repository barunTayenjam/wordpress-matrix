#!/bin/bash

# WordPress Matrix Architecture Optimizer
# Reduces containers by using shared reverse proxy

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Architecture analysis
analyze_architecture() {
    log_info "Analyzing current architecture..."
    
    local wp_containers=$(podman ps --format "{{.Names}}" | grep "^wp_" | wc -l)
    local nginx_containers=$(podman ps --format "{{.Names}}" | grep "^nginx_" | wc -l)
    local total_containers=$(podman ps --format "{{.Names}}" | wc -l)
    
    echo ""
    log_info "Current Architecture:"
    echo "  WordPress Containers: $wp_containers"
    echo "  Nginx Containers: $nginx_containers"
    echo "  Total Containers: $total_containers"
    echo ""
    
    if [[ $nginx_containers -gt 0 ]]; then
        local potential_savings=$nginx_containers
        echo "  Potential Container Savings: $potential_savings"
        echo "  Current Memory Overhead: ~$((nginx_containers * 50))MB per Nginx container"
        echo ""
        
        log_warning "Optimization Recommendations:"
        if [[ $nginx_containers -le 3 ]]; then
            echo "  • Keep current setup (good isolation, low overhead)"
        else
            echo "  • Consider shared reverse proxy (saves $nginx_containers containers)"
            echo "  • Multi-site Nginx configuration available"
        fi
    fi
}

# Show optimization options
show_optimization_options() {
    echo ""
    log_info "Available Optimizations:"
    echo ""
    echo "1. Multi-Site Nginx (Shared Reverse Proxy)"
    echo "   • Pros: Fewer containers, centralized config"
    echo "   • Cons: Single point of failure, shared resources"
    echo "   • Best: 3+ WordPress sites"
    echo ""
    echo "2. Direct PHP-FPM Port Access"
    echo "   • Pros: No reverse proxy overhead"
    echo "   • Cons: No static file optimization, security concerns"
    echo "   • Best: Development only"
    echo ""
    echo "3. Keep Current Architecture"
    echo "   • Pros: Best isolation, performance, security"
    echo "   • Cons: More containers to manage"
    echo "   • Best: Production environments"
    echo ""
    echo "4. Mixed Architecture (Optimized)"
    echo "   • Shared Nginx for development sites"
    echo "   • Dedicated Nginx for production sites"
    echo "   • Pros: Balance of optimization and isolation"
    echo ""
}

# Recommendation based on current state
provide_recommendation() {
    local nginx_containers=$(podman ps --format "{{.Names}}" | grep "^nginx_" | wc -l)
    
    echo ""
    log_success "Architecture Recommendation:"
    
    if [[ $nginx_containers -eq 0 ]]; then
        echo "  • No sites currently running"
        echo "  • Start with shared Nginx approach for efficiency"
        echo "  • Switch to dedicated for production"
    elif [[ $nginx_containers -le 2 ]]; then
        echo "  • Keep current dedicated Nginx approach"
        echo "  • Low overhead, excellent isolation"
        echo "  • Best for production and development"
    elif [[ $nginx_containers -le 5 ]]; then
        echo "  • Consider shared Nginx for development sites"
        echo "  • Keep dedicated for critical production sites"
        echo "  • Mixed approach offers good balance"
    else
        echo "  • Implement shared Nginx immediately"
        echo "  • Potential savings: $nginx_containers containers"
        echo "   - Memory: ~$((nginx_containers * 50))MB saved"
        echo "   - Management: Simpler orchestration"
        echo "   - Performance: Minimal impact"
    fi
    
    echo ""
    echo "Implementation files created:"
    echo "  • config/nginx/multi-site.conf - Shared reverse proxy config"
    echo "  • config/nginx/direct-php.conf - Direct PHP-FPM option"
}

# Main execution
main() {
    echo "🔍 WordPress Matrix Architecture Optimizer"
    echo "=========================================="
    
    analyze_architecture
    show_optimization_options
    provide_recommendation
    
    echo ""
    log_info "Architecture analysis complete!"
    echo "Choose optimization approach based on your needs."
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi