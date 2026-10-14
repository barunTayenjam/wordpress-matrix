#!/bin/bash
# Offline tests for ops hygiene (FEATURES-PLAN.md Phase 8, bash side).
# Contract:
#   matrix backup <site> --schedule=<interval> --retention=N
#     → schedule_backup writes .cron/<site>.cron marker block (idempotent)
#   cron_install / cron_remove manage crontab via marker-block diff;
#     MATRIX_CRONTAB_FILE overrides the crontab path (test seam)
#   prune_backups <dir> <N> keeps newest N .tar.gz, removes older, activity-logged
# T8.4/T8.5 (auth middleware, token-not-logged) live in frontend/__tests__/auth.test.js.

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
source "$REPO_ROOT/scripts/export-import-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/share-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/scripts/ops-lib.sh"
# shellcheck disable=SC1090,SC1091
source "$REPO_ROOT/matrix"
set +e
set -uo pipefail

# Undo matrix sourcing side effects (same pattern as other suites).
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

# --- T8.1 schedule write: marker block, fields, idempotent ---------------------
mkdir -p "$SANDBOX/wp_sched"
schedule_backup sched daily 7
cron_file="$PROJECT_ROOT/.cron/sched.cron"
assert_eq "T8.1 cron file exists" "1" "$([[ -f "$cron_file" ]] && echo 1 || echo 0)"
content=$(cat "$cron_file" 2>/dev/null || true)
assert_contains "T8.1 begin marker" "# BEGIN matrix sched" "$content"
assert_contains "T8.1 end marker" "# END matrix sched" "$content"
assert_contains "T8.1 schedule recorded" "daily" "$content"
assert_contains "T8.1 retention recorded" "7" "$content"
assert_contains "T8.1 backup cmd recorded" "backup.sh sched" "$content"
schedule_backup sched daily 7
assert_eq "T8.1 idempotent (one block)" "1" "$(grep -cF "# BEGIN matrix sched" "$cron_file")"
# schedule change rewrites the block, still one
schedule_backup sched hourly 3
assert_eq "T8.1 reschedule stays one block" "1" "$(grep -cF "# BEGIN matrix sched" "$cron_file")"
assert_contains "T8.1 reschedule updates interval" "hourly" "$(cat "$cron_file")"

# --- T8.2 cron-install / cron-remove: marker diff, non-destructive -------------
export MATRIX_CRONTAB_FILE="$SANDBOX/.crontab"
printf '# my unrelated cron job\n0 5 * * * /usr/bin/do-personal-thing\n' > "$MATRIX_CRONTAB_FILE"
cron_install sched
ct=$(cat "$MATRIX_CRONTAB_FILE")
assert_contains "T8.2 our block installed" "# BEGIN matrix sched" "$ct"
assert_contains "T8.2 foreign line preserved" "do-personal-thing" "$ct"
cron_install sched
assert_eq "T8.2 install idempotent" "1" "$(grep -cF "# BEGIN matrix sched" "$MATRIX_CRONTAB_FILE")"
cron_install sched   # re-install after schedule change updates block
assert_contains "T8.2 reinstall reflects new schedule" "hourly" "$(cat "$MATRIX_CRONTAB_FILE")"
cron_remove sched
ct=$(cat "$MATRIX_CRONTAB_FILE")
assert_eq "T8.2 remove drops our block" "0" "$(grep -cF "# BEGIN matrix sched" <<<"$ct" || true)"
assert_contains "T8.2 foreign line survives remove" "do-personal-thing" "$ct"

# --- T8.3 retention prune: 9 files, keep 3, oldest first, activity-logged ------
: > "$ACTIVITY_LOG"
mkdir -p "$SANDBOX/backups"
for i in 1 2 3 4 5 6 7 8 9; do
    touch -d "2026-10-0${i}T00:00:00" "$SANDBOX/backups/sched-${i}-bundle.tar.gz"
done
prune_backups "$SANDBOX/backups" 3
remaining=$(ls -1 "$SANDBOX/backups" | sort)
assert_eq "T8.3 keeps exactly 3" "3" "$(wc -l <<<"$remaining")"
assert_contains "T8.3 newest kept" "sched-9-bundle.tar.gz" "$remaining"
assert_contains "T8.3 second-newest kept" "sched-8-bundle.tar.gz" "$remaining"
assert_contains "T8.3 third-newest kept" "sched-7-bundle.tar.gz" "$remaining"
assert_eq "T8.3 oldest removed" "0" "$(ls "$SANDBOX/backups" | grep -c 'sched-1-bundle' || true)"
assert_contains "T8.3 prune activity-logged" "PRUNE" "$(cat "$ACTIVITY_LOG")"

echo ""
echo "ops tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
