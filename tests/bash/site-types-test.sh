#!/bin/bash
# Offline tests for multi-PHP-stack site types.
# Contract (see docs/superpowers/specs/2026-10-13-multi-php-stack-support-design.md):
#   - scripts/site-types-lib.sh registry:
#     validate_site_type, site_type_min_php, site_type_webroot,
#     site_type_uses_db, site_type_runtime_image, get_site_type,
#     set_site_type, php_at_least
#   - Types: wp laravel symfony drupal joomla grav
#   - Floors: wp 7.4, joomla/grav 8.1, laravel/symfony 8.2, drupal 8.3
#   - Webroots: wp/joomla/grav "", laravel/symfony "public", drupal "web"
#   - grav is the only no-db type
#   - .matrix-type missing => wp

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"

# ---- helpers ----
pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1"; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass
    else
        fail "$desc — expected '$expected', got '$actual'"
    fi
}

assert_rc() {
    local desc="$1" expected="$2"; shift 2
    local local_rc=0
    "$@" >/dev/null 2>&1 || local_rc=$?
    if [[ "$local_rc" == "$expected" ]]; then
        pass
    else
        fail "$desc — expected rc $expected, got $local_rc"
    fi
}

# log_* stubs so lib logging stays quiet and offline
log_info() { :; }
log_success() { :; }
log_warning() { :; }
log_error() { :; }
export -f log_info log_success log_warning log_error 2>/dev/null || true

PASS=0
FAIL=0

source "$REPO_ROOT/scripts/site-types-lib.sh"

# ---- T1: registry basics ----
assert_rc "T1.1 valid type" 0 validate_site_type laravel
assert_rc "T1.2 invalid type" 1 validate_site_type magento
assert_rc "T1.3 empty type" 1 validate_site_type ""

assert_eq "T1.4 drupal floor" "8.3" "$(site_type_min_php drupal)"
assert_eq "T1.5 wp floor" "7.4" "$(site_type_min_php wp)"
assert_eq "T1.6 laravel floor" "8.2" "$(site_type_min_php laravel)"

assert_eq "T1.7 laravel webroot" "public" "$(site_type_webroot laravel)"
assert_eq "T1.8 symfony webroot" "public" "$(site_type_webroot symfony)"
assert_eq "T1.9 drupal webroot" "web" "$(site_type_webroot drupal)"
assert_eq "T1.10 wp webroot" "" "$(site_type_webroot wp)"
assert_eq "T1.11 grav webroot" "" "$(site_type_webroot grav)"

assert_rc "T1.12 grav no db" 1 site_type_uses_db grav
assert_rc "T1.13 laravel uses db" 0 site_type_uses_db laravel
assert_rc "T1.14 wp uses db" 0 site_type_uses_db wp

assert_eq "T1.15 wp image" "wordpress:php8.3-fpm" "$(site_type_runtime_image wp 8.3)"
assert_eq "T1.16 laravel image" "matrix-php:8.2" "$(site_type_runtime_image laravel 8.2)"
assert_eq "T1.17 grav image" "matrix-php:8.1" "$(site_type_runtime_image grav 8.1)"

# ---- T2: get/set site type ----
mkdir -p "$SANDBOX/wp_alpha"
assert_eq "T2.1 missing marker => wp" "wp" "$(get_site_type alpha)"
set_site_type alpha drupal
assert_eq "T2.2 marker file content" "drupal" "$(cat "$SANDBOX/wp_alpha/.matrix-type")"
assert_eq "T2.3 get after set" "drupal" "$(get_site_type alpha)"

# ---- T3: php_at_least ----
assert_rc "T3.1 below floor" 1 php_at_least 8.1 8.2
assert_rc "T3.2 at floor" 0 php_at_least 8.3 8.2
assert_rc "T3.3 equal" 0 php_at_least 7.4 7.4
assert_rc "T3.4 major bump" 0 php_at_least 8.1 7.4

echo "site-types: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
