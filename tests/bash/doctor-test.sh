#!/bin/bash
# Offline tests for matrix doctor (FEATURES-PLAN.md Phase 5).
# Contract:
#   cmd_doctor [--json] runs ordered registry: container_runtime compose_tool
#   node_npm ports env_file disk_headroom hosts_reachability hooks_path.
#   Each check_<name> echoes status=ok|warn|fail + detail=...
#   Exit 0 unless any fail; 1 on any fail. --json prints [{check,status,detail}].
#   Env overrides for isolation: MATRIX_CHECK_PORTS MATRIX_ENV_FILE
#   MATRIX_DISK_CMD MATRIX_HOSTS_FILE CONTAINER_RUNTIME.

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
check_status() { grep -oE 'status=[a-z]+' <<<"$1" | head -1; }

log_info() { :; }; log_warning() { :; }; log_success() { :; }; log_error() { :; }
output_json() { echo "$1"; }
error_json() { echo "{\"success\":false,\"error\":{\"code\":\"$1\",\"message\":\"$2\"}}"; return 1; }

# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/config/validation.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/helpers.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/compose-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/ssl-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/doctor-lib.sh"
set +e
set -uo pipefail

# --- T5.1 isolated checks via env overrides -----------------------------------
# env_file: 600 perms → ok
export MATRIX_ENV_FILE="$SANDBOX/.env"
printf 'MYSQL_USER=x\n' > "$MATRIX_ENV_FILE"
chmod 600 "$MATRIX_ENV_FILE"
out=$(check_env_file)
assert_eq "T5.1 env_file 600 → ok" "status=ok" "$(check_status "$out")"
# 644 perms → warn (fix command printed)
chmod 644 "$MATRIX_ENV_FILE"
out=$(check_env_file)
assert_eq "T5.1 env_file 644 → warn" "status=warn" "$(check_status "$out")"
assert_contains "T5.1 env_file warn prints fix" "chmod 600" "$out"
# missing → fail
rm -f "$MATRIX_ENV_FILE"
out=$(check_env_file)
assert_eq "T5.1 env_file missing → fail" "status=fail" "$(check_status "$out")"
: > "$MATRIX_ENV_FILE"

# disk_headroom via MATRIX_DISK_CMD fake
export MATRIX_DISK_CMD="echo 'Filesystem 1024-blocks Used Available Capacity Mounted'
echo '/dev/x 100 0 3145728 0 /'"
out=$(check_disk_headroom)
assert_eq "T5.1 disk 3GiB → ok" "status=ok" "$(check_status "$out")"
export MATRIX_DISK_CMD="echo 'Filesystem 1024-blocks Used Available Capacity Mounted'
echo '/dev/x 100 0 1048576 0 /'"
out=$(check_disk_headroom)
assert_eq "T5.1 disk 1GiB → fail" "status=fail" "$(check_status "$out")"
unset MATRIX_DISK_CMD

# container_runtime: fake always-ok runtime
printf '#!/bin/sh\nexit 0\n' > "$SANDBOX/bin/fakert" && chmod +x "$SANDBOX/bin/fakert"
CONTAINER_RUNTIME=fakert out=$(CONTAINER_RUNTIME=fakert check_container_runtime)
assert_eq "T5.1 runtime ok" "status=ok" "$(check_status "$out")"
CONTAINER_RUNTIME=false out=$(CONTAINER_RUNTIME=false check_container_runtime)
assert_eq "T5.1 runtime fail" "status=fail" "$(check_status "$out")"

# --- T5.2 exit code: any fail → 1, warn-only → 0 ------------------------------
# all checks pass/warn: env_file warn (644), no failures anywhere
export MATRIX_ENV_FILE="$SANDBOX/.env"
export MATRIX_CHECK_PORTS=""
export MATRIX_HOSTS_FILE="$SANDBOX/hosts"
printf '127.0.0.1 localhost\n' > "$MATRIX_HOSTS_FILE"
cmd_doctor >/dev/null 2>&1
assert_eq "T5.2 warn-only exit 0" "0" "$?"
# force a fail: env_file missing
rm -f "$MATRIX_ENV_FILE"
cmd_doctor >/dev/null 2>&1
assert_eq "T5.2 any-fail exit 1" "1" "$?"
: > "$MATRIX_ENV_FILE"

# --- T5.3 --json shape ---------------------------------------------------------
out=$(cmd_doctor --json)
assert_contains "T5.3 json array start" '[{"check"' "$out"
assert_eq "T5.3 json parseable" "1" \
    "$(python3 -c 'import json,sys; json.load(sys.stdin); print(1)' <<<"$out" 2>/dev/null || echo 0)"

# --- T5.4 hooks check ----------------------------------------------------------
git -C "$SANDBOX" init -q
out=$(check_hooks_path)
assert_eq "T5.4 hooks unset → warn" "status=warn" "$(check_status "$out")"
assert_contains "T5.4 hooks warn prints fix command" "core.hooksPath" "$out"
git -C "$SANDBOX" config core.hooksPath .githooks
mkdir -p "$SANDBOX/.githooks"
out=$(check_hooks_path)
assert_eq "T5.4 hooks set → ok" "status=ok" "$(check_status "$out")"

# --- T5.5 port busy detection via stub ss --------------------------------------
cat > "$SANDBOX/bin/ss" << 'EOF'
#!/bin/bash
# stub: reports one listener on 8500 owned by pid 4242 cmd "node app.js"
if [[ "${1:-}" == "-tlnp" ]]; then
    echo "LISTEN 0 128 0.0.0.0:8500 0.0.0.0:* users:((\"node app.js\",pid=4242,fd=18))"
    exit 0
fi
exit 0
EOF
chmod +x "$SANDBOX/bin/ss"
export MATRIX_CHECK_PORTS="8500"
out=$(check_ports)
assert_eq "T5.5 busy port → fail" "status=fail" "$(check_status "$out")"
assert_contains "T5.5 fail names pid" "4242" "$out"
assert_contains "T5.5 fail names cmd" "node app.js" "$out"
rm -f "$SANDBOX/bin/ss"

echo ""
echo "doctor tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
