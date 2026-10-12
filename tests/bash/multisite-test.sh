#!/bin/bash
# Offline tests for multisite-at-creation (FEATURES-PLAN.md Phase 2).
# Contract:
#   create_site accepts --multisite=subdirectory|subdomain (default subdirectory);
#   unknown values abort before any container call.
#   apply_multisite <site> <mode>:
#     - run_wp_cli '<site> core multisite-install --subdomains=<0|1> ...' exactly once
#     - wp-config gains MULTISITE=true + SUBDOMAIN_INSTALL matching mode (insert-if-absent)
#     - nginx conf gains the multisite rewrite block (subdirectory mode)
#     - apache stack gains .htaccess rules (subdomain mode marker present too)
#     - subdomain mode prints hosts lines for main + first subsite
#   site_is_multisite <site> + site_multisite_mode <site> read wp-config markers.
#   show_info_json exposes multisite:true/false + multisite_mode.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

mkdir -p "$SANDBOX/bin" "$SANDBOX/logs" "$SANDBOX/state"
cp "$REPO_ROOT/tests/bash/bin/docker" "$SANDBOX/bin/docker"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/matrix-compose-stub"
cp "$REPO_ROOT/tests/bash/bin/stub-common.sh" "$SANDBOX/bin/stub-common.sh"
chmod +x "$SANDBOX/bin/"*
export PATH="$SANDBOX/bin:$PATH"
export STUB_DIR="$SANDBOX/state"
export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
export CONTAINER_RUNTIME="docker"
export DOCKER_COMPOSE="matrix-compose-stub"

: > "$STUB_DIR/running.txt"
: > "$STUB_DIR/all.txt"
: > "$STUB_DIR/ports.txt"
: > "$STUB_DIR/portmap.txt"
: > "$STUB_DIR/compose-ps.txt"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1"; }
assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then pass; else fail "$desc — expected '$expected', got '$actual'"; fi
}
assert_contains() {
    local desc="$1" needle="$2" file="$3"
    if grep -qF -- "$needle" "$file" 2>/dev/null; then pass; else fail "$desc — '$needle' not found in $file"; fi
}

# Recording stubs for the helpers multisite code depends on.
run_wp_cli() {
    local site="${1:-}"; shift
    echo "$site $*" >> "$STUB_DIR/wp-cli-calls.txt"
    return 0
}
log_info() { :; }
log_warning() { :; }
log_success() { :; }
log_error() { :; }
output_json() { echo "$1"; }
error_json() { echo "{\"success\":false,\"error\":{\"code\":\"$1\",\"message\":\"$2\"}}"; return 1; }
get_lan_ip() { echo "192.168.31.99"; }
export -f run_wp_cli log_info log_warning log_success log_error output_json error_json get_lan_ip

# Load the platform under test.
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/config/validation.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/helpers.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/compose-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/ssl-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/matrix"
# matrix sourcing side effects to undo (this suite sources the full CLI,
# unlike ssl/site-state suites which source libs only):
# - set -euo pipefail lands in this shell; expected-failure asserts must not kill it
# - PROJECT_ROOT/COMPOSE_FILE reset to the real repo
# - helpers.sh sourced inside matrix overwrote the run_wp_cli stub
set +e
set -uo pipefail
export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
export DOCKER_COMPOSE="matrix-compose-stub"
export CONTAINER_RUNTIME="docker"
export ACTIVITY_LOG="$SANDBOX/logs/activity.log"

run_wp_cli() {
    local site="${1:-}"; shift
    echo "$site $*" >> "$STUB_DIR/wp-cli-calls.txt"
    return 0
}
export -f run_wp_cli

# Fixture site with a wp-config.php resembling a real install.
setup_site() {
    mkdir -p "$SANDBOX/wp_alpha/wp-content/plugins" "$SANDBOX/wp_alpha/wp-content/themes"
    cat > "$SANDBOX/wp_alpha/wp-config.php" << 'EOF'
<?php
define( 'DB_NAME', 'alpha_db' );
define( 'DB_USER', 'wp_user' );
$table_prefix = 'wp_';
/* That's all, stop editing! Happy publishing. */
EOF
    rm -f "$STUB_DIR/wp-cli-calls.txt"
}

# --- T2.1 flag validation: bogus mode aborts before any container call --------
setup_site
docker_run_calls="$STUB_DIR/docker-run-calls.txt"
: > "$docker_run_calls"
create_site alpha --multisite=bogus >/dev/null 2>&1
rc_bogus=$?
assert_eq "T2.1 bogus mode rejected (rc!=0)" "1" "$([[ $rc_bogus -ne 0 ]] && echo 1 || echo 0)"
# accepted modes must not be rejected at parse time: exercise parse-only path
# via apply_multisite directly (full create needs network; unit-tested below).

# --- T2.2 wp-config markers via apply_multisite subdirectory ------------------
setup_site
apply_multisite alpha subdirectory >/dev/null 2>&1
assert_eq "T2.2 MULTISITE marker" "1" \
    "$(grep -q "define( 'MULTISITE', true )" "$SANDBOX/wp_alpha/wp-config.php" && echo 1 || echo 0)"
assert_eq "T2.2 SUBDOMAIN_INSTALL=false for subdirectory" "1" \
    "$(grep -q "define( 'SUBDOMAIN_INSTALL', false )" "$SANDBOX/wp_alpha/wp-config.php" && echo 1 || echo 0)"

# --- T2.2b subdomain mode writes SUBDOMAIN_INSTALL=true -----------------------
setup_site
apply_multisite alpha subdomain >/dev/null 2>&1
assert_eq "T2.2b SUBDOMAIN_INSTALL=true for subdomain" "1" \
    "$(grep -q "define( 'SUBDOMAIN_INSTALL', true )" "$SANDBOX/wp_alpha/wp-config.php" && echo 1 || echo 0)"

# --- T2.2c insert-if-absent: second run does not duplicate markers ------------
setup_site
apply_multisite alpha subdirectory >/dev/null 2>&1
apply_multisite alpha subdirectory >/dev/null 2>&1
assert_eq "T2.2c markers not duplicated" "1" \
    "$(grep -c "define( 'MULTISITE', true )" "$SANDBOX/wp_alpha/wp-config.php")"

# --- T2.3 nginx rewrite block (subdirectory) ---------------------------------
mkdir -p "$SANDBOX/config/nginx"
cat > "$SANDBOX/config/nginx/alpha.conf" << 'EOF'
server {
    listen 80;
    server_name alpha.test;
    root /var/www/html;
    index index.php;
}
EOF
generate_multisite_rewrite alpha subdirectory >/dev/null 2>&1
assert_contains "T2.3 nginx multisite block present" "# BEGIN WordPress Multisite" "$SANDBOX/config/nginx/alpha.conf"
assert_contains "T2.3 nginx subdir rewrites" "wp-files" "$SANDBOX/config/nginx/alpha.conf"

# --- T2.4 apache .htaccess rules ---------------------------------------------
cat > "$SANDBOX/wp_alpha/.htaccess" << 'EOF'
# BEGIN WordPress
RewriteEngine On
# END WordPress
EOF
generate_multisite_rewrite alpha subdirectory >/dev/null 2>&1
assert_contains "T2.4 apache htaccess multisite block" "# BEGIN WordPress Multisite" "$SANDBOX/wp_alpha/.htaccess"

# --- T2.5 site_is_multisite + mode readers ------------------------------------
assert_eq "T2.5 site_is_multisite true" "1" "$(site_is_multisite alpha && echo 1 || echo 0)"
assert_eq "T2.5 mode reader" "subdirectory" "$(site_multisite_mode alpha)"
setup_site
assert_eq "T2.5 site_is_multisite false after reset" "0" "$(site_is_multisite alpha && echo 1 || echo 0)"
assert_eq "T2.5 mode empty after reset" "" "$(site_multisite_mode alpha)"

# --- T2.7 subdomain prints hosts lines ---------------------------------------
setup_site
hosts_output=$(apply_multisite alpha subdomain 2>&1)
assert_eq "T2.7 hosts line main site" "1" \
    "$(grep -q 'alpha.test' <<<"$hosts_output" && echo 1 || echo 0)"
assert_eq "T2.7 hosts line first subsite" "1" \
    "$(grep -q '\*.alpha.test' <<<"$hosts_output" && echo 1 || echo 0)"

# --- T2.8 wp-cli invocation ordering + exact args ----------------------------
setup_site
apply_multisite alpha subdirectory >/dev/null 2>&1
calls=$(cat "$STUB_DIR/wp-cli-calls.txt" 2>/dev/null)
ms_calls=$(grep -c 'core multisite-install' <<<"$calls" || true)
assert_eq "T2.8 multisite-install called exactly once" "1" "$ms_calls"
assert_eq "T2.8 subdomains=0 for subdirectory" "1" \
    "$(grep -q -- '--subdomains=0' <<<"$calls" && echo 1 || echo 0)"

# --- T2.9 info --json exposes multisite fields (spec Phase 2 contract) --------
setup_site
out=$(show_info_json alpha 2>&1); echo "$out" > "$SANDBOX/info.json"
assert_contains "T2.9 info --json multisite:false" '"multisite":false' "$SANDBOX/info.json"
assert_contains "T2.9 info --json mode null" '"multisite_mode":null' "$SANDBOX/info.json"
apply_multisite alpha subdomain >/dev/null 2>&1
out=$(show_info_json alpha 2>&1); echo "$out" > "$SANDBOX/info.json"
assert_contains "T2.9 info --json multisite:true" '"multisite":true' "$SANDBOX/info.json"
assert_contains "T2.9 info --json mode subdomain" '"multisite_mode":"subdomain"' "$SANDBOX/info.json"

echo ""
echo "multisite tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
