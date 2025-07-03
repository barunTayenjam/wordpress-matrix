#!/bin/bash
# Platform Compatibility Test Script

set -euo pipefail

# Colors for output
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

echo "🧪 WordPress Development Platform - Compatibility Test"
echo "=================================================="

# Detect platform
case "$(uname -s)" in
    Darwin*)
        if [[ $(uname -m) == "arm64" ]]; then
            PLATFORM="Mac Silicon (ARM64)"
            ARCH="arm64"
        else
            PLATFORM="Mac Intel (x86_64)"
            ARCH="x86_64"
        fi
        ;;
    Linux*)
        if grep -q Microsoft /proc/version 2>/dev/null; then
            PLATFORM="Windows WSL2"
            ARCH="x86_64"
        else
            PLATFORM="Linux Native"
            ARCH="$(uname -m)"
        fi
        ;;
    *)
        PLATFORM="Unknown"
        ARCH="unknown"
        ;;
esac

log_info "Platform: $PLATFORM"
log_info "Architecture: $ARCH"
echo ""

# Test Docker
log_info "Testing Docker..."
if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    log_success "Docker found: $DOCKER_VERSION"
    
    if docker info >/dev/null 2>&1; then
        log_success "Docker daemon is running"
    else
        log_error "Docker daemon is not running"
        exit 1
    fi
else
    log_error "Docker not found"
    exit 1
fi

# Test Docker Compose
log_info "Testing Docker Compose..."
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f4 | cut -d',' -f1)
    log_success "Docker Compose found: $COMPOSE_VERSION"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short)
    log_success "Docker Compose (plugin) found: $COMPOSE_VERSION"
else
    log_error "Docker Compose not found"
    exit 1
fi

# Test system resources
log_info "Testing system resources..."

# Memory
if command -v free >/dev/null 2>&1; then
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_MEM -ge 8 ]]; then
        log_success "Memory: ${TOTAL_MEM}GB (sufficient)"
    else
        log_warning "Memory: ${TOTAL_MEM}GB (minimum 8GB recommended)"
    fi
elif command -v vm_stat >/dev/null 2>&1; then
    # macOS
    TOTAL_MEM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    if [[ $TOTAL_MEM -ge 8 ]]; then
        log_success "Memory: ${TOTAL_MEM}GB (sufficient)"
    else
        log_warning "Memory: ${TOTAL_MEM}GB (minimum 8GB recommended)"
    fi
fi

# Disk space
AVAILABLE_SPACE=$(df -h . | awk 'NR==2{print $4}' | sed 's/G.*//')
if [[ ${AVAILABLE_SPACE%.*} -ge 20 ]]; then
    log_success "Disk space: ${AVAILABLE_SPACE} (sufficient)"
else
    log_warning "Disk space: ${AVAILABLE_SPACE} (minimum 20GB recommended)"
fi

# CPU cores
CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
if [[ $CPU_CORES != "unknown" && $CPU_CORES -ge 2 ]]; then
    log_success "CPU cores: $CPU_CORES (sufficient)"
else
    log_warning "CPU cores: $CPU_CORES (minimum 2 cores recommended)"
fi

# Platform-specific tests
echo ""
log_info "Platform-specific tests..."

case $PLATFORM in
    "Mac Silicon"*)
        # Test Rosetta 2 for AMD64 containers
        if /usr/bin/pgrep oahd >/dev/null 2>&1; then
            log_success "Rosetta 2 is available for AMD64 emulation"
        else
            log_warning "Rosetta 2 not detected (may be needed for some containers)"
        fi
        
        # Test Docker Desktop settings
        if docker info | grep -q "Operating System.*Docker Desktop"; then
            log_success "Docker Desktop detected"
        else
            log_warning "Docker Desktop not detected"
        fi
        ;;
        
    "Linux"*)
        # Test vm.max_map_count for Elasticsearch
        MAX_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
        if [[ $MAX_MAP_COUNT -ge 262144 ]]; then
            log_success "vm.max_map_count: $MAX_MAP_COUNT (sufficient for Elasticsearch)"
        else
            log_warning "vm.max_map_count: $MAX_MAP_COUNT (should be >= 262144 for Elasticsearch)"
            log_info "Run: echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"
        fi
        
        # Test Docker permissions
        if groups | grep -q docker; then
            log_success "User is in docker group"
        else
            log_warning "User not in docker group (may need sudo for Docker commands)"
            log_info "Run: sudo usermod -aG docker \$USER && newgrp docker"
        fi
        ;;
        
    "Windows WSL2"*)
        # Test WSL2 version
        if command -v wsl.exe >/dev/null 2>&1; then
            WSL_VERSION=$(wsl.exe -l -v 2>/dev/null | grep -E '\*|Ubuntu|Debian' | head -1 | awk '{print $3}' || echo "unknown")
            if [[ $WSL_VERSION == "2" ]]; then
                log_success "WSL2 detected"
            else
                log_warning "WSL version: $WSL_VERSION (WSL2 recommended)"
            fi
        fi
        
        # Test filesystem location
        if [[ $PWD == /mnt/* ]]; then
            log_warning "Project in Windows filesystem (consider moving to WSL2 filesystem for better performance)"
            log_info "Recommended location: ~/wp-dev-platform"
        else
            log_success "Project in WSL2 filesystem (optimal performance)"
        fi
        ;;
esac

# Test network connectivity
echo ""
log_info "Testing network connectivity..."
if curl -s --connect-timeout 5 https://hub.docker.com >/dev/null; then
    log_success "Docker Hub connectivity: OK"
else
    log_warning "Docker Hub connectivity: Failed (may affect image downloads)"
fi

# Test multi-platform support
echo ""
log_info "Testing multi-platform support..."
if docker buildx version >/dev/null 2>&1; then
    log_success "Docker Buildx available (multi-platform builds supported)"
    
    # Check available platforms
    PLATFORMS=$(docker buildx inspect default 2>/dev/null | grep "Platforms:" | cut -d: -f2 | tr ',' '\n' | wc -l)
    if [[ $PLATFORMS -gt 1 ]]; then
        log_success "Multiple platforms supported: $PLATFORMS"
    else
        log_warning "Limited platform support detected"
    fi
else
    log_warning "Docker Buildx not available (limited multi-platform support)"
fi

# Summary
echo ""
echo "🎯 Compatibility Summary"
echo "======================="
log_info "Platform: $PLATFORM"
log_info "Architecture: $ARCH"
log_info "Docker: $DOCKER_VERSION"
log_info "Docker Compose: $COMPOSE_VERSION"

echo ""
if [[ $PLATFORM == "Mac Silicon"* ]]; then
    log_success "✅ Fully compatible with Mac Silicon"
    log_info "🚀 Native ARM64 performance with AMD64 emulation fallback"
elif [[ $PLATFORM == "Mac Intel"* ]]; then
    log_success "✅ Fully compatible with Mac Intel"
    log_info "🚀 Native x86_64 performance"
elif [[ $PLATFORM == "Linux"* ]]; then
    log_success "✅ Fully compatible with Linux"
    log_info "🚀 Native Docker performance"
elif [[ $PLATFORM == "Windows WSL2"* ]]; then
    log_success "✅ Compatible with Windows WSL2"
    log_info "🚀 Good performance via WSL2 integration"
else
    log_warning "⚠️  Platform compatibility unknown"
fi

echo ""
log_info "Ready to run: ./wp-dev setup && ./wp-dev start"