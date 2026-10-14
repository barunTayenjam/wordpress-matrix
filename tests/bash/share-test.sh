#!/bin/bash
# Offline tests for matrix share (FEATURES-PLAN.md Phase 4).
# Contract:
#   detect_share_provider → first of cloudflared|ngrok|bore on PATH, else ""
#   provider_url_from_log <provider> <logfile> → public URL or ""
#   share_site <site> [--provider=P] [--yes] [--json]
#     SHARE_SITE_NOT_RUNNING when site not running
#     SHARE_NO_PROVIDER when nothing on PATH
#     SHARE_CONFIRM_REQUIRED without --yes on non-tty
#     --yes: warning printed once, proceeds; cleanup trap kills child + pidfile

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

mkdir -p "$SANDBOX/bin" "$SANDBOX/logs" "$SANDBOX/state" "$SANDBOX/empty"
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

log_info() { :; }; log_warning() { :; }; log_success() { :; }; log_error() { :; }
output_json() { echo "$1"; }
error_json() { echo "{\"success\":false,\"error\":{\"code\":\"$1\",\"message\":\"$2\"}}"; return 1; }
log_activity() { :; }

# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/config/validation.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/helpers.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/ssl-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/share-lib.sh"
# --- Undo matrix sourcing side effects (same pattern as other test suites) ---
set +e
set -uo pipefail
# Sandbox bin FIRST so stubs shadow host binaries; host /usr/bin stays in the
# PATH for coreutils (grep/rm/etc.) — detection tables below use dedicated
# dirs placed ahead of even the sandbox bin to control what is visible.
export PATH="$SANDBOX/bin:/usr/bin:/bin"
export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
export DOCKER_COMPOSE="matrix-compose-stub"
export CONTAINER_RUNTIME="docker"
export ACTIVITY_LOG="$SANDBOX/logs/activity.log"

# --- T4.1 detection table (via MATRIX_SHARE_PATH seam; no PATH mutation) ---------
mkdir -p "$SANDBOX/only-cloudflared" "$SANDBOX/only-bore"
printf '#!/bin/bash\nexit 0\n' > "$SANDBOX/only-cloudflared/cloudflared"
printf '#!/bin/bash\nexit 0\n' > "$SANDBOX/only-bore/bore"
chmod +x "$SANDBOX/only-cloudflared/cloudflared" "$SANDBOX/only-bore/bore"
export MATRIX_SHARE_PATH="$SANDBOX/only-cloudflared"
assert_eq "T4.1 fake cloudflared → cloudflared" "cloudflared" "$(detect_share_provider)"
export MATRIX_SHARE_PATH="$SANDBOX/only-bore"
assert_eq "T4.1 fake bore (alone) → bore" "bore" "$(detect_share_provider)"
export MATRIX_SHARE_PATH="$SANDBOX/empty"
assert_eq "T4.1 nothing visible → empty" "" "$(detect_share_provider)"
unset MATRIX_SHARE_PATH

# --- T4.4 url extraction from fixture logs ---------------------------------------
printf '2026-10-12T10:00:00Z INF |  https://odd-frog-1234.trycloudflare.com |\n' > "$SANDBOX/cf.log"
out=$(provider_url_from_log cloudflared "$SANDBOX/cf.log")
assert_contains "T4.4 cloudflared URL extracted" "trycloudflare.com" "$out"
assert_eq "T4.4 bare URL only" "https://odd-frog-1234.trycloudflare.com" "$out"
printf 'addr https://abc-def-123.ngrok-free.app\n' > "$SANDBOX/ng.log"
out=$(provider_url_from_log ngrok "$SANDBOX/ng.log")
assert_eq "T4.4 ngrok URL extracted" "https://abc-def-123.ngrok-free.app" "$out"
: > "$SANDBOX/none.log"
assert_eq "T4.4 no url → empty" "" "$(provider_url_from_log cloudflared "$SANDBOX/none.log")"

# --- T4.2 SHARE_SITE_NOT_RUNNING -------------------------------------------------
out=$(share_site ghost 2>&1)
assert_contains "T4.2 not running → SHARE_SITE_NOT_RUNNING" '"code":"SHARE_SITE_NOT_RUNNING"' "$out"

# --- fixture: a RUNNING site (docker stub running.txt) ----------------------------
printf 'wp_demo\n' > "$STUB_DIR/running.txt"
printf 'nginx_demo 8299\n' > "$STUB_DIR/portmap.txt"

# fake provider: prints a tunnel URL immediately, then sleeps until killed
cat > "$SANDBOX/bin/cloudflared" << 'EOF'
#!/bin/bash
echo "INF |  https://stub-tunnel-99.trycloudflare.com |"
sleep 300
EOF
chmod +x "$SANDBOX/bin/cloudflared"

# runner: lets `timeout` drive share_site (functions can't be exec'd directly)
cat > "$SANDBOX/bin/run-share" << EOF
#!/bin/bash
set -uo pipefail
export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
export CONTAINER_RUNTIME="docker"
export DOCKER_COMPOSE="matrix-compose-stub"
export ACTIVITY_LOG="$SANDBOX/logs/activity.log"
export STUB_DIR="$SANDBOX/state"
export PATH="\$PATH"
output_json() { echo "\$1"; }
error_json() { echo "{\"success\":false,\"error\":{\"code\":\"\$1\",\"message\":\"\$2\"}}"; return 1; }
log_activity() { :; }
source "$REPO_ROOT/config/validation.sh"
source "$REPO_ROOT/scripts/helpers.sh"
source "$REPO_ROOT/scripts/ssl-lib.sh"
source "$REPO_ROOT/scripts/share-lib.sh"
share_site "\$@"
EOF
chmod +x "$SANDBOX/bin/run-share"

# --- T4.3 --yes gate ----------------------------------------------------------------
# non-tty without --yes → SHARE_CONFIRM_REQUIRED
out=$(share_site demo --provider=cloudflared 2>&1)
assert_contains "T4.3 non-tty no --yes → SHARE_CONFIRM_REQUIRED" '"code":"SHARE_CONFIRM_REQUIRED"' "$out"
# with --yes: warning once, then proceeds
out=$(timeout 5 "$SANDBOX/bin/run-share" demo --provider=cloudflared --yes 2>&1)
assert_contains "T4.3 --yes prints warning once" "publicly reachable" "$out"
assert_contains "T4.3 --yes proceeds to URL" "stub-tunnel-99" "$out"

# --- T4.5 cleanup: timeout kills child, pidfile gone ---------------------------------
timeout 0.5 "$SANDBOX/bin/run-share" demo --provider=cloudflared --yes >/dev/null 2>&1
assert_eq "T4.5 pidfile removed on TERM" "0" "$([[ -f /tmp/matrix-share-demo.pid ]] && echo 1 || echo 0)"
# the stub child itself must be dead (not orphaned)
assert_eq "T4.5 stub child killed" "0" "$(pgrep -fc 'sleep 300' || true)"
rm -f "$SANDBOX/bin/cloudflared" /tmp/matrix-share-demo.*

# --- T4.6 --json emits provider+url line ---------------------------------------------
cat > "$SANDBOX/bin/bore" << 'EOF'
#!/bin/bash
echo "listening at https://stub-bore.example.com:4040"
sleep 300
EOF
chmod +x "$SANDBOX/bin/bore"
out=$(timeout 5 "$SANDBOX/bin/run-share" demo --provider=bore --yes --json 2>&1)
assert_contains "T4.6 json line" '"provider":"bore"' "$out"
assert_contains "T4.6 json url" '"url":"https://stub-bore.example.com:4040"' "$out"
rm -f "$SANDBOX/bin/bore" /tmp/matrix-share-demo.*

# --- T4.7 SHARE_NO_PROVIDER (MATRIX_SHARE_PATH empty; no PATH mutation) -----------
export MATRIX_SHARE_PATH="$SANDBOX/empty"
out=$(share_site demo 2>&1)
assert_contains "T4.7 no provider → SHARE_NO_PROVIDER" '"code":"SHARE_NO_PROVIDER"' "$out"
unset MATRIX_SHARE_PATH

echo ""
echo "share tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
