#!/bin/bash
# Test script for wp-podman functionality

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

log_pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; ((PASS++)); }
log_fail() { echo -e "${RED}❌ FAIL${NC}: $1"; ((FAIL++)); }
log_info() { echo -e "${YELLOW}ℹ️  INFO${NC}: $1"; }

# Test 1: Script exists and is executable
test_script_exists() {
    if [[ -x "./wp-podman" ]]; then
        log_pass "wp-podman script exists and is executable"
    else
        log_fail "wp-podman script not found or not executable"
    fi
}

# Test 2: Help command works
test_help_command() {
    if ./wp-podman help >/dev/null 2>&1; then
        log_pass "Help command works"
    else
        log_fail "Help command failed"
    fi
}

# Test 3: Runtime detection
test_runtime_detection() {
    local runtime_output
    runtime_output=$(./wp-podman runtime 2>/dev/null)
    if echo "$runtime_output" | grep -q "Container Runtime:"; then
        log_pass "Runtime detection works"
        log_info "Detected runtime: $(echo "$runtime_output" | head -1)"
    else
        log_fail "Runtime detection failed"
    fi
}

# Test 4: Podman detection
test_podman_detection() {
    if command -v podman >/dev/null 2>&1; then
        log_pass "Podman is installed"
        local podman_version
        podman_version=$(podman --version 2>/dev/null)
        log_info "Podman version: $podman_version"
    else
        log_fail "Podman not found"
    fi
}

# Test 5: podman-compose detection
test_podman_compose_detection() {
    if command -v podman-compose >/dev/null 2>&1; then
        log_pass "podman-compose is installed"
        local compose_version
        compose_version=$(podman-compose version 2>/dev/null || echo "Version check failed")
        log_info "podman-compose: $compose_version"
    else
        log_fail "podman-compose not found"
    fi
}

# Test 6: Site listing (should handle empty state gracefully)
test_site_listing() {
    local list_output
    list_output=$(./wp-podman list 2>&1)
    if echo "$list_output" | grep -q "WordPress Sites"; then
        log_pass "Site listing works"
    else
        log_fail "Site listing failed"
    fi
}

# Test 7: Configuration files creation
test_setup_creates_files() {
    # Backup existing files
    [[ -f ".env" ]] && cp .env .env.backup
    [[ -f "docker-compose.yml" ]] && cp docker-compose.yml docker-compose.yml.backup
    
    # Run setup
    ./wp-podman setup >/dev/null 2>&1 || true
    
    # Check if files were created
    if [[ -f ".env" ]]; then
        log_pass ".env file created by setup"
    else
        log_fail ".env file not created by setup"
    fi
    
    if [[ -f "docker-compose.yml" ]]; then
        log_pass "docker-compose.yml created by setup"
    else
        log_fail "docker-compose.yml not created by setup"
    fi
    
    # Restore backups
    [[ -f ".env.backup" ]] && mv .env.backup .env || rm -f .env
    [[ -f "docker-compose.yml.backup" ]] && mv docker-compose.yml.backup docker-compose.yml || rm -f docker-compose.yml
}

# Test 8: Error handling for invalid commands
test_invalid_command() {
    if ./wp-podman invalid-command 2>&1 | grep -q "Unknown command"; then
        log_pass "Invalid command handling works"
    else
        log_fail "Invalid command handling failed"
    fi
}

# Run all tests
echo "🧪 Testing wp-podman script..."
echo "================================"

test_script_exists
test_help_command
test_runtime_detection
test_podman_detection
test_podman_compose_detection
test_site_listing
test_setup_creates_files
test_invalid_command

echo "================================"
echo "Test Results: $PASS passed, $FAIL failed"

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi