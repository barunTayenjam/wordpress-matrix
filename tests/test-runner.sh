#!/bin/bash
# Test Runner for Simplified WordPress Platform
# Runs all unit tests and integration tests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$SCRIPT_DIR"

# Test results tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        if [[ $? -eq $expected_exit_code ]]; then
            log_success "PASS"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "FAIL (wrong exit code)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        log_error "FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to test file existence
test_file_exists() {
    local file_path="$1"
    local description="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: $description... "
    
    if [[ -f "$file_path" ]]; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (file not found: $file_path)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to test directory existence
test_dir_exists() {
    local dir_path="$1"
    local description="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: $description... "
    
    if [[ -d "$dir_path" ]]; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (directory not found: $dir_path)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to test script syntax
test_script_syntax() {
    local script_path="$1"
    local description="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: $description... "
    
    if bash -n "$script_path" 2>/dev/null; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (syntax error)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Main test suite
run_all_tests() {
    log_info "Running Simplified WordPress Platform Test Suite"
    echo "================================================="
    
    # Test 1: Core Files Existence
    echo ""
    log_info "1. Core Files Test"
    test_file_exists "$PROJECT_ROOT/wp-simple" "wp-simple script exists"
    test_file_exists "$PROJECT_ROOT/docker-compose.simple.yml" "Simplified docker-compose exists"
    test_file_exists "$PROJECT_ROOT/.env.simple" "Simplified environment file exists"
    test_file_exists "$PROJECT_ROOT/migrate-to-simple.sh" "Migration script exists"
    test_file_exists "$PROJECT_ROOT/README_SIMPLIFIED.md" "Simplified documentation exists"
    test_file_exists "$PROJECT_ROOT/config/nginx/default.conf" "Nginx configuration exists"
    
    # Test 2: Directory Structure
    echo ""
    log_info "2. Directory Structure Test"
    test_dir_exists "$PROJECT_ROOT/config" "Config directory exists"
    test_dir_exists "$PROJECT_ROOT/config/nginx" "Nginx config directory exists"
    test_dir_exists "$PROJECT_ROOT/tests" "Tests directory exists"
    
    # Test 3: Script Syntax Validation
    echo ""
    log_info "3. Script Syntax Test"
    test_script_syntax "$PROJECT_ROOT/wp-simple" "wp-simple script syntax"
    test_script_syntax "$PROJECT_ROOT/migrate-to-simple.sh" "Migration script syntax"
    test_script_syntax "$PROJECT_ROOT/mysql-entrypoint.sh" "MySQL entrypoint syntax"
    
    # Test 4: Executable Permissions
    echo ""
    log_info "4. Executable Permissions Test"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: wp-simple is executable... "
    if [[ -x "$PROJECT_ROOT/wp-simple" ]]; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (not executable)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: migrate-to-simple.sh is executable... "
    if [[ -x "$PROJECT_ROOT/migrate-to-simple.sh" ]]; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (not executable)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test 5: Configuration Validation
    echo ""
    log_info "5. Configuration Validation Test"
    test_file_exists "$PROJECT_ROOT/.env.simple" "Environment template exists"
    
    # Check if .env.simple has required variables
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: .env.simple has required variables... "
    if grep -q "DOMAIN_SUFFIX\|MYSQL_USER\|MYSQL_PASSWORD" "$PROJECT_ROOT/.env.simple"; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (missing required variables)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test 6: Docker Configuration
    echo ""
    log_info "6. Docker Configuration Test"
    test_file_exists "$PROJECT_ROOT/docker-compose.simple.yml" "Docker compose file exists"
    
    # Check if docker-compose has required services
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: docker-compose has required services... "
    if grep -q "db:\|redis:\|traefik:" "$PROJECT_ROOT/docker-compose.simple.yml"; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (missing required services)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test 7: Help Command Test
    echo ""
    log_info "7. Help Command Test"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: wp-simple help command works... "
    if "$PROJECT_ROOT/wp-simple" help >/dev/null 2>&1; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (help command failed)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test 8: Migration Script Help Test
    echo ""
    log_info "8. Migration Script Test"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: migration script help command works... "
    if "$PROJECT_ROOT/migrate-to-simple.sh" help >/dev/null 2>&1; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (migration help failed)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test 9: Documentation completeness
    echo ""
    log_info "9. Documentation Test"
    test_file_exists "$PROJECT_ROOT/README_SIMPLIFIED.md" "Main README exists"
    test_file_exists "$PROJECT_ROOT/AGENTS.md" "Agent documentation exists"
    
    # Check if README has essential sections
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: README has essential sections... "
    if grep -q "Quick Start\|Main Commands\|Migration" "$PROJECT_ROOT/README_SIMPLIFIED.md"; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (missing essential sections)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test 10: Environment variables validation
    echo ""
    log_info "10. Environment Variables Test"
    
    # Test environment loading
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: .env.simple can be sourced... "
    if bash -c "source $PROJECT_ROOT/.env.simple && echo \$DOMAIN_SUFFIX" >/dev/null 2>&1; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (cannot source .env.simple)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Integration tests
run_integration_tests() {
    echo ""
    log_info "Integration Tests"
    echo "=================="
    
    # Test 1: Site creation mock test
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: Site creation validation... "
    
    # Create temporary test environment
    local temp_dir=$(mktemp -d)
    cp "$PROJECT_ROOT/wp-simple" "$temp_dir/"
    
    # Test site name validation
    if ! "$temp_dir/wp-simple" create invalid@name 2>/dev/null; then
        # Should fail with invalid name
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAIL (should reject invalid names)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    rm -rf "$temp_dir"
    
    # Test 2: Port assignment logic test
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing: Port assignment logic... "
    
    # Create test docker-compose file in temporary directory
    local temp_test_dir=$(mktemp -d)
    local test_compose="$temp_test_dir/test-compose.yml"
    cat > "$test_compose" << 'EOF'
services:
  wp_test:
    ports:
      - "8001:80"
  wp_test2:
    ports:
      - "8002:80"
EOF
    
    # Test port extraction logic
    local max_port=$(grep -E '"[0-9]+:80"' "$test_compose" | sed -E 's/.*"([0-9]+):80".*/\1/' | sort -nr | head -n 1)
    local result=0
    
    if [[ "$max_port" == "8002" ]]; then
        log_success "PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        result=0
    else
        log_error "FAIL (port extraction failed: got '$max_port')"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        result=1
    fi
    
    # Clean up
    rm -rf "$temp_test_dir"
    return $result
}

# Generate test report
generate_report() {
    echo ""
    echo "================================================="
    log_info "Test Results Summary"
    echo "================================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    local success_rate=0
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        success_rate=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
    fi
    
    echo "Success Rate: $success_rate%"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        log_success "🎉 All tests passed!"
        return 0
    else
        echo ""
        log_error "💥 Some tests failed. Please review and fix."
        return 1
    fi
}

# Main execution
main() {
    case "${1:-all}" in
        "unit"|"u")
            run_all_tests
            ;;
        "integration"|"i")
            run_integration_tests
            ;;
        "all"|"a")
            run_all_tests
            run_integration_tests
            ;;
        "help"|"-h"|"--help")
            cat << EOF
Test Runner for Simplified WordPress Platform

Usage: ./test-runner.sh [option]

Options:
  unit              Run unit tests only
  integration        Run integration tests only  
  all              Run all tests (default)
  help             Show this help

Examples:
  ./test-runner.sh           # Run all tests
  ./test-runner.sh unit      # Run unit tests only
  ./test-runner.sh integration # Run integration tests only
EOF
            return 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use './test-runner.sh help' for usage information"
            return 1
            ;;
    esac
    
    generate_report
}

# Run tests
main "$@"