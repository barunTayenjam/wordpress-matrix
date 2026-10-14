#!/bin/bash
# Offline tests for presets-as-files (FEATURES-PLAN.md Phase 3).
# Contract:
#   config/presets/<name>.sh defines: preset_description() [required],
#   preset_plugins() preset_theme() preset_wp_config() preset_post_install() [optional]
#   apply_preset <site> <p>  validates name, sources file, runs hooks
#   list_presets             lists dir + descriptions
#   error codes: PRESET_UNKNOWN, PRESET_INVALID_NAME (json via error_json)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

mkdir -p "$SANDBOX/bin" "$SANDBOX/logs" "$SANDBOX/state"
cp "$REPO_ROOT/tests/bash/bin/docker" "$SANDBOX/bin/docker"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/matrix-compose-stub"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/docker-compose"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/podman-compose"
cp "$REPO_ROOT/tests/bash/bin/stub-common.sh" "$SANDBOX/bin/stub-common.sh"
chmod +x "$SANDBOX/bin/"*
export PATH="$SANDBOX/bin:$PATH"
export STUB_DIR="$SANDBOX/state"
export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
export CONTAINER_RUNTIME="docker"
export DOCKER_COMPOSE="matrix-compose-stub"
export MATRIX_PRESETS_DIR="$SANDBOX/config/presets"
export ACTIVITY_LOG="$SANDBOX/logs/activity.log"
: > "$STUB_DIR/running.txt"
: > "$STUB_DIR/all.txt"
: > "$STUB_DIR/ports.txt"
: > "$STUB_DIR/portmap.txt"
: > "$STUB_DIR/compose-ps.txt"
: > "$STUB_DIR/wp-cli-calls.txt"

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
log_info() { :; }
log_warning() { :; }
log_success() { :; }
log_error() { :; }
output_json() { echo "$1"; }
error_json() { echo "{\"success\":false,\"error\":{\"code\":\"$1\",\"message\":\"$2\"}}"; return 1; }
get_lan_ip() { echo "192.168.31.99"; }
export -f run_wp_cli log_info log_warning log_success log_error output_json error_json get_lan_ip

# --- sandbox preset files (drop-in convention under test) --------------------
mkdir -p "$SANDBOX/config/presets" "$SANDBOX/wp_t3/wp-content/plugins"
cat > "$SANDBOX/config/presets/woocommerce.sh" << 'EOF'
#!/bin/bash
preset_description() { echo "WooCommerce with starter theme"; }
preset_plugins() { echo "woocommerce"; }
preset_theme() { echo ""; }
EOF
cat > "$SANDBOX/config/presets/bbpress.sh" << 'EOF'
#!/bin/bash
preset_description() { echo "bbPress forum plugin"; }
preset_plugins() { echo "bbpress"; }
EOF
cat > "$SANDBOX/config/presets/buddypress.sh" << 'EOF'
#!/bin/bash
preset_description() { echo "BuddyPress social network"; }
preset_plugins() { echo "buddypress"; }
preset_wp_config() { echo "WP_MEMORY_LIMIT=256M"; }
EOF
cat > "$SANDBOX/config/presets/blank.sh" << 'EOF'
#!/bin/bash
preset_description() { echo "Empty WordPress installation"; }
EOF

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
source "$REPO_ROOT/scripts/presets-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/matrix"
set +e
set -uo pipefail

# Undo matrix sourcing side effects (same as multisite-test.sh):
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

# T3.1 golden parity: apply_preset records the exact WP-CLI sequence the
# hardcoded case used to run (migration safety net, TDD-IMPLEMENTATION.md).
: > "$STUB_DIR/wp-cli-calls.txt"
apply_preset t3 woocommerce >/dev/null 2>&1
calls=$(cat "$STUB_DIR/wp-cli-calls.txt")
assert_eq "T3.1 golden parity: woocommerce install exactly once" "1" \
    "$(grep -c 'plugin install woocommerce --activate --allow-root' <<<"$calls")"

# T3.2 unknown preset -> error_json PRESET_UNKNOWN listing available
out=$(apply_preset t3 unknown-preset 2>&1)
assert_contains "T3.2 PRESET_UNKNOWN code" '"code":"PRESET_UNKNOWN"' "$out"
assert_contains "T3.2 lists available presets" "blank" "$out"

# T3.3 name validation: path traversal -> PRESET_INVALID_NAME, nothing sourced
out=$(apply_preset t3 '../evil' 2>&1)
assert_contains "T3.3 path traversal rejected" '"code":"PRESET_INVALID_NAME"' "$out"

# T3.4 blank preset: no hooks called
: > "$STUB_DIR/wp-cli-calls.txt"
apply_preset t3 blank >/dev/null 2>&1
assert_eq "T3.4 blank: no wp-cli call" "0" "$(wc -l < "$STUB_DIR/wp-cli-calls.txt")"

# T3.5 preset listing shows name + description for each file
out=$(list_presets 2>&1)
assert_contains "T3.5 lists woocommerce" "woocommerce" "$out"
assert_contains "T3.5 lists bbpress" "bbpress" "$out"
assert_contains "T3.5 lists blank" "blank" "$out"
assert_contains "T3.5 shows descriptions" "bbPress forum plugin" "$out"

# T3.6 loader applies hooks beyond plugins: theme + wp_config + post_install
cat > "$SANDBOX/config/presets/demo.sh" << 'EOF'
#!/bin/bash
preset_description() { echo "Demo preset"; }
preset_plugins() { echo "demo-plugin"; }
preset_theme() { echo "demo-theme"; }
preset_wp_config() { echo "DEMO_KEY=demo-value"; }
preset_post_install() { run_wp_cli "$PRESET_SITE" demo-hook; }
EOF
cat > "$SANDBOX/wp_t3/wp-config.php" << 'EOF'
<?php
define( 'DB_NAME', 't3_db' );
/* That's all, stop editing! Happy publishing. */
EOF
: > "$STUB_DIR/wp-cli-calls.txt"
apply_preset t3 demo >/dev/null 2>&1
calls=$(cat "$STUB_DIR/wp-cli-calls.txt")
assert_contains "T3.6 plugin hook ran" "plugin install demo-plugin --activate --allow-root" "$calls"
assert_contains "T3.6 theme hook ran" "theme install demo-theme --activate --allow-root" "$calls"
assert_contains "T3.6 post_install hook ran" "demo-hook" "$calls"
assert_contains "T3.6 wp_config define written" "define( 'DEMO_KEY', 'demo-value' );" "$(cat "$SANDBOX/wp_t3/wp-config.php")"
# re-run: wp_config insert-if-absent (multisite precedent)
apply_preset t3 demo >/dev/null 2>&1
assert_eq "T3.6 wp_config not duplicated" "1" \
    "$(grep -c "define( 'DEMO_KEY', 'demo-value' );" "$SANDBOX/wp_t3/wp-config.php")"

# T3.7 list_presets --json: machine-readable for the dashboard
out=$(list_presets --json 2>&1)
assert_contains "T3.7 json success shape" '"success":true' "$out"
assert_contains "T3.7 json presets array" '"presets":[' "$out"
assert_contains "T3.7 json name+description pair" '{"name":"woocommerce","description":"WooCommerce with starter theme"}' "$out"

echo ""
echo "presets tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
