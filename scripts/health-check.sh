#!/bin/bash
# System health check

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$SCRIPT_DIR/common.sh"

echo "🔍 WordPress Matrix Health Check"
echo "=================================="
echo ""

# Check Docker/Podman
log_info "Checking container runtime..."
if command -v docker >/dev/null 2>&1; then
    log_success "Docker found: $(docker --version)"
    DOCKER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
    log_success "Podman found: $(podman --version)"
    DOCKER_CMD="podman"
else
    log_error "Neither Docker nor Podman found"
    exit 1
fi

# Check docker-compose
log_info "Checking docker-compose..."
if $DOCKER_CMD compose version >/dev/null 2>&1; then
    log_success "docker-compose found"
elif command -v docker-compose >/dev/null 2>&1; then
    log_success "docker-compose (standalone) found"
else
    log_error "docker-compose not found"
    exit 1
fi

echo ""

# Check containers status
log_info "Checking container status..."
containers_running=$($DOCKER_CMD ps --format "{{.Names}}" | wc -l | tr -d ' ')
log_success "Containers running: $containers_running"

# Check database
log_info "Checking database..."
if $DOCKER_CMD ps | grep -q "wp_db.*Up"; then
    log_success "Database container: Running"
else
    log_error "Database container: Not running"
fi

# Test database connection
if $DOCKER_COMPOSE exec db mysqladmin ping -h localhost --silent 2>/dev/null; then
    log_success "Database connection: OK"
else
    log_error "Database connection: FAILED"
fi

echo ""

# Check Redis
log_info "Checking Redis..."
if $DOCKER_CMD ps | grep -q "wp_redis.*Up"; then
    log_success "Redis container: Running"
    if $DOCKER_COMPOSE exec redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis connection: OK"
    else
        log_error "Redis connection: FAILED"
    fi
else
    log_warning "Redis container: Not running"
fi

echo ""

# Check WordPress sites
log_info "Checking WordPress sites..."
sites_count=$(get_sites | wc -l | tr -d ' ')
log_success "WordPress sites: $sites_count"

for site in $(get_sites); do
    if $DOCKER_CMD ps | grep -q "wp_$site.*Up"; then
        log_success "  $site: Running"
    else
        log_warning "  $site: Stopped"
    fi
done

echo ""

# Check disk space
log_info "Checking disk space..."
df_output=$(df -h "$PROJECT_ROOT" | tail -1)
disk_usage=$(echo "$df_output" | awk '{print $5}')
disk_available=$(echo "$df_output" | awk '{print $4}')
log_success "Disk usage: $disk_usage (available: $disk_available)"

if [[ ${disk_usage%?} -gt 80 ]]; then
    log_warning "Disk usage is high!"
fi

echo ""

# Check memory usage
log_info "Checking memory usage..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    memory_info=$(vm_stat | perl -ne '/page size of (\d+)/ and $ps=$1; /Pages free:\s+(\d+)/ and printf "%.2f GB free\n", ($1*$ps)/1024/1024/1024')
    log_info "$memory_info"
elif [[ -f /proc/meminfo ]]; then
    mem_free=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_percent=$((100 - (mem_free * 100 / mem_total)))
    log_success "Memory usage: ${mem_percent}%"
fi

echo ""

# Check port conflicts
log_info "Checking port conflicts..."
for site in $(get_sites); do
    port=$(get_site_port "$site")
    if [[ -n "$port" ]]; then
        if ss -tln 2>/dev/null | grep -q ":$port "; then
            log_success "  Port $port ($site): In use"
        else
            log_warning "  Port $port ($site): Not listening"
        fi
    fi
done

echo ""

# Check logs
log_info "Checking for errors in logs..."
error_count=0
for site in $(get_sites); do
    if $DOCKER_COMPOSE logs --tail=50 "wp_$site" 2>&1 | grep -i "error\|fatal" | grep -q .; then
        log_warning "  Errors found in: $site"
        ((error_count++))
    fi
done

if [[ $error_count -eq 0 ]]; then
    log_success "No errors found in recent logs"
fi

echo ""

# Summary
echo "=================================="
log_success "Health check complete!"

if [[ $error_count -gt 0 ]]; then
    log_warning "Found $error_count sites with errors - check logs with: ./matrix logs <site>"
fi
