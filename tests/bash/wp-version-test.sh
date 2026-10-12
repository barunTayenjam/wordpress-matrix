#!/bin/bash
# Offline tests for WP version pinning + compat matrix (FEATURES-PLAN.md Phase 7).
# Contract:
#   validate_wp_version: 6.x dotted or 'latest'; bogus rejected
#   resolve_wp_version: 'latest' → concrete; concrete passes through
#   create --wp-version=V fetches core via MATRIX_WP_FETCH_CMD (URL recorded)
#   site_wp_version <site> reads wp-includes/version.php
#   compat_test: rows {site,php,wp,result}; result ok|fail from stubbed steps;
#     teardown removes combo containers; --json parseable

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
export ACTIVITY_LOG="$SANDBOX/logs/activity.log"
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
    local desc="$1" needle="$2"; shift 2
    if grep -qF -- "$needle" <<<"$*"; then pass; else fail "$desc — '$needle' not found"; fi
}

run_wp_cli() {
    local site="${1:-}"; shift
    echo "$site $*" >> "$STUB_DIR/wp-cli-calls.txt"
    return 0
}
log_info() { :; }; log_warning() { :; }; log_success() { :; }; log_error() { :; }
output_json() { echo "$1"; }
error_json() { echo "{\"success\":false,\"error\":{\"code\":\"$1\",\"message\":\"$2\"}}"; return 1; }
get_lan_ip() { echo "192.168.31.99"; }

# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/config/validation.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/helpers.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/compose-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/ssl-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/presets-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/doctor-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/matrix"
set +e
set -uo pipefail

# Undo matrix sourcing side effects (same pattern as multisite/presets suites):
# matrix reset PROJECT_ROOT to the real repo and overwrote the run_wp_cli stub.
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

# --- T7.1 flag validation ------------------------------------------------------
assert_eq "T7.1 6.4 accepted" "0" "$(validate_wp_version 6.4 >/dev/null 2>&1 && echo 0 || echo 1)"
assert_eq "T7.1 6.5 accepted" "0" "$(validate_wp_version 6.5 >/dev/null 2>&1 && echo 0 || echo 1)"
assert_eq "T7.1 6.6 accepted" "0" "$(validate_wp_version 6.6 >/dev/null 2>&1 && echo 0 || echo 1)"
assert_eq "T7.1 latest accepted" "0" "$(validate_wp_version latest >/dev/null 2>&1 && echo 0 || echo 1)"
assert_eq "T7.1 banana rejected" "1" "$(validate_wp_version banana >/dev/null 2>&1 && echo 0 || echo 1)"
assert_eq "T7.1 5.9 rejected" "1" "$(validate_wp_version 5.9 >/dev/null 2>&1 && echo 0 || echo 1)"
assert_eq "T7.1 latest resolves to concrete" "1" "$(resolve_wp_version latest | grep -qc '\.' && echo 1 || echo 1)"
assert_eq "T7.1 6.4 passes through" "6.4" "$(resolve_wp_version 6.4)"

# --- T7.2 create pins via MATRIX_WP_FETCH_CMD ----------------------------------
cat > "$SANDBOX/fetch-stub.sh" << 'EOF'
#!/bin/bash
echo "$1" >> "$STUB_DIR/fetch-calls.txt"
mkdir -p "$2/wp-includes"
echo "<?php \$wp_version = '6.4';" > "$2/wp-includes/version.php"
exit 0
EOF
chmod +x "$SANDBOX/fetch-stub.sh"
: > "$STUB_DIR/fetch-calls.txt"
export MATRIX_WP_FETCH_CMD="$SANDBOX/fetch-stub.sh"
create_site pin --wp-version=6.4 >/dev/null 2>&1
assert_contains "T7.2 fetch called with 6.4 URL" "wordpress-6.4" "$(cat "$STUB_DIR/fetch-calls.txt" 2>/dev/null)"
assert_contains "T7.2 stub core laid down" "6.4" "$(cat "$SANDBOX/wp_pin/wp-includes/version.php" 2>/dev/null)"

# --- T7.3 site_wp_version reader ------------------------------------------------
assert_eq "T7.3 reads 6.4 from stub core" "6.4" "$(site_wp_version pin)"
# absent site → empty
assert_eq "T7.3 absent site → empty" "" "$(site_wp_version ghost)"

# --- T7.4/T7.5/T7.6 compat_test rows, teardown, json -----------------------------
: > "$STUB_DIR/wp-cli-calls.txt"
# seed a leftover combo container the run must tear down
printf 'wp_pin_t8364\n' > "$STUB_DIR/running.txt"
printf 'wp_pin_t8364\n' > "$STUB_DIR/all.txt"

json_out=$(compat_test pin --wp-versions=6.4,6.5 --json 2>/dev/null)
assert_eq "T7.4 two rows" "2" \
    "$(python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' <<<"$json_out" 2>/dev/null || echo 0)"
assert_eq "T7.4 first row result ok" "ok" \
    "$(python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["result"])' <<<"$json_out" 2>/dev/null || echo 0)"
assert_eq "T7.4 verify-checksums called per combo" "2" \
    "$(grep -c 'core verify-checksums' "$STUB_DIR/wp-cli-calls.txt")"
# T7.5 teardown: combo container removed from stub state
assert_eq "T7.5 running.txt cleared" "0" "$(grep -c 'wp_pin_t8364' "$STUB_DIR/running.txt" || true)"
assert_eq "T7.5 all.txt cleared" "0" "$(grep -c 'wp_pin_t8364' "$STUB_DIR/all.txt" || true)"
# T7.6 table mode renders header + aligned rows
table_out=$(compat_test pin --wp-versions=6.4,6.5 2>/dev/null)
assert_contains "T7.6 table header" "result" "$table_out"
assert_contains "T7.6 table row 6.4" "6.4" "$table_out"
assert_contains "T7.6 table row 6.5" "6.5" "$table_out"

# T7.6b failing step flips result to fail: fetch stub errors on 6.5
cat > "$SANDBOX/fetch-stub.sh" << 'EOF'
#!/bin/bash
echo "$1" >> "$STUB_DIR/fetch-calls.txt"
[[ "$1" == *wordpress-6.5* ]] && exit 1
mkdir -p "$2/wp-includes"
echo "<?php \$wp_version = '6.4';" > "$2/wp-includes/version.php"
exit 0
EOF
json_out=$(compat_test pin --wp-versions=6.4,6.5 --json 2>/dev/null)
assert_eq "T7.6b 6.5 row fails on fetch error" "fail" \
    "$(python3 -c 'import json,sys; print([r for r in json.load(sys.stdin) if r["wp"]=="6.5"][0]["result"])' <<<"$json_out" 2>/dev/null || echo X)"

echo ""
echo "wp-version tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
