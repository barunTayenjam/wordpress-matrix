#!/bin/bash
# Offline tests for site export/import bundle (FEATURES-PLAN.md Phase 6).
# Contract:
#   export_site <site> [--out FILE] [--json] → tar.gz: manifest.json (LAST member),
#     files/ (site dir, excludes logs/, .git), db/site.sql.gz
#   import_site <bundle> <new-site> [--yes] [--json] → validates manifest + sha,
#     create_site skeleton (--skip-download), restores files, db via seams,
#     prints search-replace dry-run
#   errors: EXPORT_SITE_MISSING, IMPORT_MANIFEST_INVALID, IMPORT_SHA_MISMATCH, IMPORT_NAME_TAKEN
#   Seams (re-stubbed here): dump_site_db, db_exec_root, db_import_dump

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

# Undo matrix sourcing side effects + re-stub (same pattern as other suites).
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
# DB seams (Phase 6): dump / root exec / dump-import, re-stubbed for offline tests.
dump_site_db() { echo "CREATE TABLE wp_custom_posts (ID bigint);"; }
db_exec_root() { echo "$*" >> "$STUB_DIR/db-sql.txt"; return 0; }
db_import_dump() { echo "IMPORT $1 INTO $2" >> "$STUB_DIR/db-sql.txt"; return 0; }
export -f run_wp_cli dump_site_db db_exec_root db_import_dump

# --- fixture -------------------------------------------------------------------
create_fixture_site() {
    local site="$1"
    mkdir -p "$PROJECT_ROOT/wp_$site/wp-content" "$PROJECT_ROOT/config/nginx"
    cat > "$PROJECT_ROOT/wp_$site/wp-config.php" << EOF
<?php
define( 'DB_NAME', '${site}_db' );
define( 'DB_USER', 'wp_user' );
\$table_prefix = 'wp_custom_';
EOF
    touch "$PROJECT_ROOT/wp_$site/wp-content/dummy.txt"
    echo "nginx" > "$PROJECT_ROOT/wp_$site/.matrix-stack"
    cat > "$PROJECT_ROOT/config/nginx/$site.conf" << EOF
server { listen 80; server_name _; }
EOF
}

# --- T6.1 export: tar exists, manifest fields correct ---------------------------
create_fixture_site fix
mkdir -p "$SANDBOX/out" "$SANDBOX/backups"
export_site fix --out "$SANDBOX/out/fix-bundle.tar.gz"
assert_eq "T6.1 export rc" "0" "$?"
assert_eq "T6.1 tar exists" "1" "$([[ -s "$SANDBOX/out/fix-bundle.tar.gz" ]] && echo 1 || echo 0)"
tar_members=$(tar -tzf "$SANDBOX/out/fix-bundle.tar.gz")
assert_contains "T6.1 bundle has files/" "files/" "$tar_members"
assert_contains "T6.1 bundle has db dump" "db/site.sql.gz" "$tar_members"
assert_contains "T6.1 bundle has manifest" "manifest.json" "$tar_members"
manifest=$(tar -xzf "$SANDBOX/out/fix-bundle.tar.gz" -O manifest.json 2>/dev/null || true)
assert_contains "T6.1 manifest site" '"site":"fix"' "$manifest"
assert_contains "T6.1 manifest wp_version" '"wp_version"' "$manifest"
assert_contains "T6.1 manifest table_prefix" '"table_prefix":"wp_custom_"' "$manifest"
assert_contains "T6.1 manifest db_dump_sha256" '"db_dump_sha256"' "$manifest"
assert_contains "T6.1 manifest stack" '"stack":"nginx"' "$manifest"

# manifest is the LAST tar member (deterministic order per spec)
last_member=$(tar -tzf "$SANDBOX/out/fix-bundle.tar.gz" | tail -1)
assert_eq "T6.1 manifest last member" "manifest.json" "$last_member"

# export of missing site
out=$(export_site ghost --out "$SANDBOX/out/ghost.tar.gz" 2>&1)
assert_contains "T6.1 missing site → EXPORT_SITE_MISSING" '"code":"EXPORT_SITE_MISSING"' "$out"

# --- T6.2 sha mismatch on corrupted dump ----------------------------------------
mkdir -p "$SANDBOX/tmp"
tar -xzf "$SANDBOX/out/fix-bundle.tar.gz" -C "$SANDBOX/tmp"
echo "corrupt" >> "$SANDBOX/tmp/db/site.sql.gz"
tar -czf "$SANDBOX/out/corrupt.tar.gz" -C "$SANDBOX/tmp" files db manifest.json
out=$(import_site "$SANDBOX/out/corrupt.tar.gz" fix2 2>&1)
assert_contains "T6.2 corrupt dump → IMPORT_SHA_MISMATCH" '"code":"IMPORT_SHA_MISMATCH"' "$out"
rm -rf "$SANDBOX/tmp"

# invalid manifest
mkdir -p "$SANDBOX/tmp2/files" "$SANDBOX/tmp2/db"
echo "not json" > "$SANDBOX/tmp2/manifest.json"
echo "CREATE TABLE t (i int);" | gzip > "$SANDBOX/tmp2/db/site.sql.gz"
tar -czf "$SANDBOX/out/bad-manifest.tar.gz" -C "$SANDBOX/tmp2" files db manifest.json
out=$(import_site "$SANDBOX/out/bad-manifest.tar.gz" fix3 2>&1)
assert_contains "T6.2 bad manifest → IMPORT_MANIFEST_INVALID" '"code":"IMPORT_MANIFEST_INVALID"' "$out"
rm -rf "$SANDBOX/tmp2"

# --- T6.3 import: files restored, db create recorded, compose+nginx regenerated ---
: > "$STUB_DIR/db-sql.txt"
import_site "$SANDBOX/out/fix-bundle.tar.gz" imported
assert_eq "T6.3 import rc" "0" "$?"
assert_eq "T6.3 site dir created" "1" "$([[ -d "$PROJECT_ROOT/wp_imported" ]] && echo 1 || echo 0)"
assert_contains "T6.3 wp-config restored w/ custom prefix" "wp_custom_" "$(cat "$PROJECT_ROOT/wp_imported/wp-config.php")"
assert_contains "T6.3 files restored" "dummy.txt" "$(ls "$PROJECT_ROOT/wp_imported/wp-content")"
db_sql=$(cat "$STUB_DIR/db-sql.txt")
assert_contains "T6.3 db create recorded" "CREATE DATABASE" "$db_sql"
assert_contains "T6.3 db create names imported_db" "imported_db" "$db_sql"
assert_contains "T6.3 dump import recorded" "INTO imported_db" "$db_sql"
assert_eq "T6.3 nginx conf regenerated" "1" "$([[ -f "$PROJECT_ROOT/config/nginx/imported.conf" ]] && echo 1 || echo 0)"
assert_contains "T6.3 nginx conf routes to new site" "wp_imported:9000" "$(cat "$PROJECT_ROOT/config/nginx/imported.conf")"
assert_contains "T6.3 compose entry added" "wp_imported" "$(cat "$COMPOSE_FILE")"
assert_eq "T6.3 original site untouched" "1" "$([[ -f "$PROJECT_ROOT/wp_fix/wp-content/dummy.txt" ]] && echo 1 || echo 0)"
assert_eq "T6.3 original nginx conf intact" "1" "$([[ -f "$PROJECT_ROOT/config/nginx/fix.conf" ]] && echo 1 || echo 0)"

# --- T6.4 name taken without --yes; --yes allows overwrite ----------------------
out=$(import_site "$SANDBOX/out/fix-bundle.tar.gz" imported 2>&1)
assert_contains "T6.4 existing site → IMPORT_NAME_TAKEN" '"code":"IMPORT_NAME_TAKEN"' "$out"
import_site "$SANDBOX/out/fix-bundle.tar.gz" imported --yes
assert_eq "T6.4 --yes overwrite rc" "0" "$?"

# --- T6.5 table prefix round-trip (already in T6.3; explicit) -------------------
assert_contains "T6.5 prefix round-trips" "wp_custom_" "$(cat "$PROJECT_ROOT/wp_imported/wp-config.php")"

# --- T6.6 excludes: logs/, .git absent from tar ---------------------------------
mkdir -p "$PROJECT_ROOT/wp_fix/logs" "$PROJECT_ROOT/wp_fix/.git"
touch "$PROJECT_ROOT/wp_fix/logs/x.log" "$PROJECT_ROOT/wp_fix/.git/config"
export_site fix --out "$SANDBOX/out/fix2.tar.gz"
members=$(tar -tzf "$SANDBOX/out/fix2.tar.gz")
assert_eq "T6.6 logs excluded" "0" "$(grep -c 'logs/' <<<"$members" || true)"
assert_eq "T6.6 .git excluded" "0" "$(grep -c '\.git' <<<"$members" || true)"

# --- T6.7 --json both commands ---------------------------------------------------
out=$(export_site fix --out "$SANDBOX/out/fix-json.tar.gz" --json 2>/dev/null)
assert_contains "T6.7 export json" '"success":true' "$out"
out=$(import_site "$SANDBOX/out/fix-json.tar.gz" fixjson --json 2>/dev/null)
assert_contains "T6.7 import json" '"success":true' "$out"

echo ""
echo "export-import tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
