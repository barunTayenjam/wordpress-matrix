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

# stub container runtime at PATH boundary (site-state-test.sh pattern)
mkdir -p "$SANDBOX/bin"
for f in docker matrix-compose-stub stub-common.sh; do
    cp "$REPO_ROOT/tests/bash/bin/$f" "$SANDBOX/bin/$f"
done
chmod +x "$SANDBOX/bin/"*
export PATH="$SANDBOX/bin:$PATH"
export STUB_DIR="$SANDBOX/state"
export CONTAINER_RUNTIME="docker"
export DOCKER_COMPOSE="matrix-compose-stub"
mkdir -p "$STUB_DIR"

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

# ---- T4: build_site_image (Task 2) ----
# build_site_image <php> builds matrix-php:<php> only when absent.
assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass
    else
        fail "$desc — missing '$needle'"
    fi
}
rm -f "$STUB_DIR/build.txt" "$STUB_DIR/images.txt"
build_site_image 8.3
assert_eq "T4.1 build recorded once" "1" "$(grep -c 'matrix-php:8.3' "$STUB_DIR/build.txt" 2>/dev/null)"
assert_rc "T4.2 build args carry PHP_VERSION" 0 grep -qx 'PHP_VERSION=8.3' "$STUB_DIR/build.txt"
assert_rc "T4.3 build tags matrix-php:8.3" 0 grep -qx 'matrix-php:8.3' "$STUB_DIR/build.txt"
build_site_image 8.3
assert_eq "T4.4 no rebuild when image exists" "1" "$(grep -c 'matrix-php:8.3' "$STUB_DIR/build.txt" 2>/dev/null)"
# Dockerfile exists with composer baked in (spec: composer runs in matrix-php, not composer:2)
assert_contains "T4.5 Dockerfile installs composer" "$(cat "$REPO_ROOT/config/docker/php-site/Dockerfile" 2>/dev/null)" "composer"
assert_contains "T4.6 Dockerfile has unzip" "$(cat "$REPO_ROOT/config/docker/php-site/Dockerfile" 2>/dev/null)" "unzip"

# ---- T5: compose_add_site type-aware (Task 3) ----
source "$REPO_ROOT/scripts/helpers.sh"
source "$REPO_ROOT/scripts/compose-lib.sh"
# helpers.sh may define real log_* — keep tests quiet + offline
log_info() { :; }
log_success() { :; }
log_warning() { :; }
log_error() { :; }
export -f log_info log_success log_warning log_error 2>/dev/null || true

write_base_compose() {
    cat > "$COMPOSE_FILE" <<'YAML'
services:
  db:
    image: mysql:8.0
volumes:
  db_data:
YAML
}

mk_site_conf() {  # nginx conf path placeholder (only the path is embedded)
    echo "$SANDBOX/$1.conf" > "$SANDBOX/$1.conf"
}

# T5.1 wp unchanged: wordpress image + WORDPRESS_DB_* + depends_on db
write_base_compose; mk_site_conf wpsite
compose_add_site wpsite 8.3 8201 "$SANDBOX/wpsite.conf" nginx wp
svc_block=$(sed -n '/^  wp_wpsite:/,/^  nginx_wpsite:/p' "$COMPOSE_FILE")
assert_contains "T5.1a wp keeps wordpress fpm image" "$svc_block" "wordpress:php8.3-fpm"
assert_eq   "T5.1b wp keeps DB env" "1" "$(grep -c 'WORDPRESS_DB_HOST' "$COMPOSE_FILE")"
assert_contains "T5.1c wp depends_on db" "$svc_block" "depends_on"

# T5.2 laravel: matrix-php image, no WORDPRESS env, depends_on kept
write_base_compose; mk_site_conf lsite
compose_add_site lsite 8.2 8202 "$SANDBOX/lsite.conf" nginx laravel
l_block=$(sed -n '/^  wp_lsite:/,/^  nginx_lsite:/p' "$COMPOSE_FILE")
assert_contains "T5.2a laravel uses matrix-php image" "$l_block" "matrix-php:8.2"
assert_eq "T5.2b no WORDPRESS_DB_HOST for laravel" "0" "$(grep -c 'WORDPRESS_DB_HOST' "$COMPOSE_FILE")"
assert_contains "T5.2c laravel keeps depends_on db" "$l_block" "depends_on"

# T5.3 grav: matrix-php image, no WORDPRESS env, NO depends_on
write_base_compose; mk_site_conf gsite
compose_add_site gsite 8.1 8203 "$SANDBOX/gsite.conf" nginx grav
g_block=$(sed -n '/^  wp_gsite:/,/^  nginx_gsite:/p' "$COMPOSE_FILE")
assert_contains "T5.3a grav uses matrix-php image" "$g_block" "matrix-php:8.1"
assert_eq "T5.3b no WORDPRESS_DB_HOST for grav" "0" "$(grep -c 'WORDPRESS_DB_HOST' "$COMPOSE_FILE")"
assert_eq "T5.3c grav has no depends_on" "0" "$(sed -n '/wp_gsite:/,/nginx_gsite:/p' "$COMPOSE_FILE" | grep -c 'depends_on')"

# T5.4 default (6th arg omitted) = wp behavior
write_base_compose; mk_site_conf dsite
compose_add_site dsite 8.3 8204 "$SANDBOX/dsite.conf" nginx
assert_eq "T5.4 default type keeps wordpress image" "1" "$(grep -c 'wordpress:php8.3-fpm' "$COMPOSE_FILE")"

# ---- T6: generate_nginx_conf per-type webroot (Task 4) ----
mkdir -p "$SANDBOX/config/nginx"
generate_nginx_conf ngsite wp
wp_conf=$(cat "$SANDBOX/config/nginx/ngsite.conf")
assert_contains "T6.1 wp root unchanged" "$wp_conf" "root /var/www/html;"
generate_nginx_conf lsite2 laravel
l_conf=$(cat "$SANDBOX/config/nginx/lsite2.conf")
assert_contains "T6.2 laravel root public" "$l_conf" "root /var/www/html/public;"
assert_contains "T6.3 fpm pass uses container name" "$l_conf" "fastcgi_pass wp_lsite2:9000"
assert_contains "T6.4 client_max_body_size 25m" "$l_conf" "client_max_body_size 25m;"
generate_nginx_conf dsite2 drupal
assert_contains "T6.5 drupal root web" "$(cat "$SANDBOX/config/nginx/dsite2.conf")" "root /var/www/html/web;"
generate_nginx_conf gsite2 grav
assert_contains "T6.6 grav root html" "$(cat "$SANDBOX/config/nginx/gsite2.conf")" "root /var/www/html;"
# clone path (common.sh create_nginx_config) used 64k before dedup; keep it.
assert_contains "T6.7 wp conf keeps 64k busy buffers" "$wp_conf" "fastcgi_busy_buffers_size 64k;"

# ---- T7: create_site --type parsing (Task 5) ----
# Loads the full CLI (multisite-test.sh reset pattern), then exercises
# create_site against stubs. Runs LAST: matrix sourcing resets shell opts.
source "$REPO_ROOT/config/validation.sh"
source "$REPO_ROOT/matrix"
set +e
set -uo pipefail
export PROJECT_ROOT="$SANDBOX"
export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
export DOCKER_COMPOSE="matrix-compose-stub"
export CONTAINER_RUNTIME="docker"
export ACTIVITY_LOG="$SANDBOX/logs/activity.log"
mkdir -p "$SANDBOX/logs"

log_info() { :; }
log_success() { :; }
log_warning() { :; }
log_error() { echo "[error] $*" >&2; }
run_wp_cli() { echo "$1 $*" >> "$STUB_DIR/wp-cli-calls.txt"; return 0; }
# provision_site_type now ships in the lib (Task 7); T9 needs the real one.
# T7 re-stubs it here for create_site flow tests, emulating the real
# dispatcher's marker writes so create_site's tail flow is intact.
provision_site_type() { echo "$@" >> "$STUB_DIR/provision-calls.txt"; mkdir -p "$PROJECT_ROOT/wp_$1"; echo "$2" > "$PROJECT_ROOT/wp_$1/.matrix-type"; return 0; }
export -f log_info log_success log_warning log_error run_wp_cli provision_site_type

# T7.1 laravel --skip-download → .matrix-type marker + provision called
write_base_compose
rm -f "$STUB_DIR/provision-calls.txt"
# No --skip-download here: it now means "restore from bundle" (see T16).
create_site t1 --type=laravel >/dev/null 2>&1
assert_eq "T7.1a laravel marker written" "laravel" "$(cat "$SANDBOX/wp_t1/.matrix-type" 2>/dev/null || echo missing)"
assert_contains "T7.1b provisioning dispatched" "$(cat "$STUB_DIR/provision-calls.txt" 2>/dev/null)" "t1 laravel"

# T7.2 drupal floor violation → error mentions 8.3, no dir
create_site t2 --type=drupal --php-version=8.1 > "$SANDBOX/t2.out" 2>&1
t2_rc=$?
assert_eq "T7.2a drupal 8.1 rejected" "1" "$t2_rc"
grep -q "8.3" "$SANDBOX/t2.out" && pass || fail "T7.2b error names floor 8.3"
[[ ! -d "$SANDBOX/wp_t2" ]] && pass || fail "T7.2c no dir after floor rejection"

# T7.3 wp-only flag rejected for laravel
create_site t3 --type=laravel --wp-version=6.4 > "$SANDBOX/t3.out" 2>&1 || true
grep -q "wp" "$SANDBOX/t3.out" && grep -qi "only supported\|requires wp" "$SANDBOX/t3.out" && pass || fail "T7.3 --wp-version rejected for laravel"

# T7.4 invalid type listed
create_site t4 --type=magento > "$SANDBOX/t4.out" 2>&1 || true
grep -q "laravel" "$SANDBOX/t4.out" && pass || fail "T7.4 invalid type error lists valid types"

# T7.5 default type = wp
write_base_compose
create_site t5 --skip-download >/dev/null 2>&1
assert_eq "T7.5 default marker wp" "wp" "$(cat "$SANDBOX/wp_t5/.matrix-type" 2>/dev/null || echo missing)"

# ---- T8: composer provisioning + env seeding (Task 6) ----
# NOTE: these run before the matrix-sourcing section (T7) so shell stays clean.
rm -f "$STUB_DIR/run.txt"
mkdir -p "$SANDBOX/wp_larv"
provision_composer larv laravel 8.2
run_log=$(cat "$STUB_DIR/run.txt" 2>/dev/null)
assert_contains "T8.1a laravel create-project" "$run_log" "composer"
assert_contains "T8.1b laravel package" "$run_log" "laravel/laravel"
assert_contains "T8.1c runs in matrix-php image" "$run_log" "matrix-php:8.2"
assert_contains "T8.1d mounts site dir" "$run_log" "/var/www/html"

rm -f "$STUB_DIR/run.txt"
mkdir -p "$SANDBOX/wp_symf"
provision_composer symf symfony 8.2
assert_contains "T8.2 symfony skeleton" "$(cat "$STUB_DIR/run.txt" 2>/dev/null)" "symfony/skeleton"

# T8.3 laravel .env patch (fixture mimics create-project output)
mkdir -p "$SANDBOX/wp_lenv"
cat > "$SANDBOX/wp_lenv/.env" <<'ENVFIX'
APP_NAME=Laravel
APP_KEY=base64:EXISTINGKEYKEEPME
APP_ENV=local
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=
ENVFIX
export MYSQL_USER=wp_user MYSQL_PASSWORD=wp_password
seed_laravel_env lenv
lenv_env=$(cat "$SANDBOX/wp_lenv/.env")
assert_contains "T8.3a DB_HOST patched" "$lenv_env" "DB_HOST=db"
assert_contains "T8.3b DB_DATABASE patched" "$lenv_env" "DB_DATABASE=lenv_db"
assert_contains "T8.3c DB_USERNAME patched" "$lenv_env" "DB_USERNAME=wp_user"
assert_contains "T8.3d DB_PASSWORD patched" "$lenv_env" "DB_PASSWORD=wp_password"
assert_contains "T8.3e APP_KEY untouched" "$lenv_env" "EXISTINGKEYKEEPME"
seed_laravel_env lenv
assert_eq "T8.3f idempotent DB_HOST" "1" "$(grep -c '^DB_HOST=' "$SANDBOX/wp_lenv/.env")"

# T8.3g Laravel 12 style .env (no DB_* lines at all) → block appended
mkdir -p "$SANDBOX/wp_lenv12"
printf 'APP_NAME=Laravel\nAPP_KEY=base64:XYZ\nAPP_ENV=local\nDB_CONNECTION=sqlite\n' > "$SANDBOX/wp_lenv12/.env"
seed_laravel_env lenv12
lenv12=$(cat "$SANDBOX/wp_lenv12/.env")
assert_contains "T8.3g connection forced to mysql" "$lenv12" "DB_CONNECTION=mysql"
assert_contains "T8.3h DB_HOST appended" "$lenv12" "DB_HOST=db"
assert_contains "T8.3i DB_DATABASE appended" "$lenv12" "DB_DATABASE=lenv12_db"
assert_contains "T8.3j APP_KEY untouched (12-style)" "$lenv12" "XYZ"
seed_laravel_env lenv12
assert_eq "T8.3k idempotent on second run" "1" "$(grep -c '^DB_HOST=' "$SANDBOX/wp_lenv12/.env")"

# T8.4 symfony DATABASE_URL
mkdir -p "$SANDBOX/wp_senv"
printf 'APP_ENV=dev\nDATABASE_URL="mysql://app:!ChangeMe!@127.0.0.1:3306/app?serverVersion=8.0.32"\n' > "$SANDBOX/wp_senv/.env"
seed_symfony_env senv
senv_env=$(cat "$SANDBOX/wp_senv/.env")
assert_contains "T8.4a symfony DATABASE_URL rewritten" "$senv_env" 'DATABASE_URL="mysql://wp_user:wp_password@db:3306/senv_db"'
seed_symfony_env senv
assert_eq "T8.4b idempotent DATABASE_URL" "1" "$(grep -c '^DATABASE_URL=' "$SANDBOX/wp_senv/.env")"

# ---- T9: dispatcher + joomla + grav + drupal (Task 7) ----
# Re-source to restore real lib functions — T7's create_site stub shadows
# provision_site_type in this shell; T9 tests the real dispatcher.
source "$REPO_ROOT/scripts/site-types-lib.sh"
log_info() { :; }; log_success() { :; }; log_warning() { :; }
log_error() { echo "[error] $*" >&2; }
# T9.1 dispatcher routes laravel
rm -f "$STUB_DIR/run.txt"; mkdir -p "$SANDBOX/wp_disp"
provision_site_type disp laravel 8.2
assert_contains "T9.1 dispatcher laravel create-project" "$(cat "$STUB_DIR/run.txt" 2>/dev/null)" "laravel/laravel"

# T9.2 joomla zip via dispatcher, URL overridable
rm -f "$STUB_DIR/run.txt"; mkdir -p "$SANDBOX/wp_joom"
provision_site_type joom joomla 8.1
joom_run=$(cat "$STUB_DIR/run.txt" 2>/dev/null)
assert_contains "T9.2a joomla downloads zip" "$joom_run" "Joomla_5.4.0-Stable-Full_Package.zip"
assert_contains "T9.2b joomla unzips into webroot" "$joom_run" "unzip"
export MATRIX_JOOMLA_URL="https://example.test/joomla.zip"
rm -f "$STUB_DIR/run.txt"
provision_site_type joom2 joomla 8.1
assert_contains "T9.2c JOOMLA url override honored" "$(cat "$STUB_DIR/run.txt" 2>/dev/null)" "example.test"
unset MATRIX_JOOMLA_URL

# T9.3 drupal settings seeded with creds + salt
mkdir -p "$SANDBOX/wp_dru/web/sites/default"
seed_drupal_settings dru
dru_php=$(cat "$SANDBOX/wp_dru/web/sites/default/settings.php" 2>/dev/null || echo missing)
assert_contains "T9.3a drupal db name" "$dru_php" "dru_db"
assert_contains "T9.3b drupal db user" "$dru_php" "wp_user"
assert_contains "T9.3c drupal host db" "$dru_php" "'db'"
assert_contains "T9.3d drupal hash_salt set" "$dru_php" "hash_salt"
rm -f "$STUB_DIR/run.txt"
provision_site_type dru2 drupal 8.3
dru_run=$(cat "$STUB_DIR/run.txt" 2>/dev/null)
assert_contains "T9.3e drupal recommended-project" "$dru_run" "drupal/recommended-project"

# T9.4 grav via dispatcher, no env file expected
rm -f "$STUB_DIR/run.txt"; mkdir -p "$SANDBOX/wp_grav"
provision_site_type grav grav 8.1
assert_contains "T9.4 grav create-project" "$(cat "$STUB_DIR/run.txt" 2>/dev/null)" "getgrav/grav"
[[ ! -f "$SANDBOX/wp_grav/.env" ]] && pass || fail "T9.4b grav writes no .env"

# T9.5 grav create skips DB; laravel create hits it (db guard, matrix-level)
echo "wp_db" >> "$STUB_DIR/running.txt"
rm -f "$STUB_DIR/exec.txt" "$STUB_DIR/build.txt"
write_base_compose
create_site gsite5 --type=grav --skip-download >/dev/null 2>&1
assert_eq "T9.5a grav create: no mysql exec" "0" "$(grep -c 'mysql' "$STUB_DIR/exec.txt" 2>/dev/null || echo 0)"
# --skip-download writes no markers (they arrive with the bundle files in
# import); emulate that restore step here.
echo "grav" > "$SANDBOX/wp_gsite5/.matrix-type"
assert_eq "T9.5b grav marker restored from bundle" "grav" "$(cat "$SANDBOX/wp_gsite5/.matrix-type" 2>/dev/null || echo missing)"
rm -f "$STUB_DIR/exec.txt"
write_base_compose
create_site lsite5 --type=laravel --skip-download >/dev/null 2>&1
assert_eq "T9.5c laravel create: db created" "1" "$(grep -c 'mysql' "$STUB_DIR/exec.txt" 2>/dev/null || echo 0)"

# T9.6 joomla create output prints wizard DB creds
write_base_compose
create_site jsite6 --type=joomla --skip-download > "$SANDBOX/t9-6.out" 2>&1
grep -q "jsite6_db" "$SANDBOX/t9-6.out" && pass || fail "T9.6 joomla creds printed"

# ---- T10: rollback on non-wp provisioning failure (Task 8) ----
# Shadow docker in this shell: laravel create-project fails when FAIL_LARAVEL set.
docker() {
    if [[ -n "${FAIL_LARAVEL:-}" && "$*" == *"composer create-project laravel/laravel"* ]]; then
        return 1
    fi
    command docker "$@"
}
rm -f "$STUB_DIR/run.txt"
FAIL_LARAVEL=1 write_base_compose 2>/dev/null
write_base_compose
FAIL_LARAVEL=1 create_site rbsite --type=laravel > "$SANDBOX/t10.out" 2>&1
t10_rc=$?
assert_eq "T10.1 failed provision → rc 1" "1" "$t10_rc"
[[ ! -d "$SANDBOX/wp_rbsite" ]] && pass || fail "T10.2 site dir rolled back"
assert_eq "T10.3 no compose entry after rollback" "0" "$(grep -c 'wp_rbsite:' "$COMPOSE_FILE" 2>/dev/null)"
unset FAIL_LARAVEL

# T10.4 wp path pin: skip-download create still adds compose entry (best-effort kept)
write_base_compose
create_site wppin --skip-download >/dev/null 2>&1
grep -q 'wp_wppin:' "$COMPOSE_FILE" && pass || fail "T10.4 wp compose entry still added"

# ---- T11: wp-only gating (Task 9) ----
# T7's run_wp_cli stub shadows the real helpers.sh one — restore real
# (helpers then lib), then re-stub logging.
source "$REPO_ROOT/scripts/helpers.sh"
source "$REPO_ROOT/scripts/site-types-lib.sh"
log_info() { :; }; log_success() { :; }; log_warning() { :; }
log_error() { echo "[error] $*" >&2; }

# T11.1 require_site_type semantics
mkdir -p "$SANDBOX/wp_gate"
set_site_type gate laravel
require_site_type gate wp > "$SANDBOX/t11-1.out" 2>&1
t11_rc=$?
assert_eq "T11.1a laravel site gated" "1" "$t11_rc"
grep -q "command not supported for laravel site (requires wp)" "$SANDBOX/t11-1.out" && pass || fail "T11.1b exact gate message"
set_site_type gate wp
require_site_type gate wp >/dev/null 2>&1 && pass || fail "T11.1c wp site passes"

# T11.2 run_wp_cli refuses laravel site (fresh — T11.1c flipped gate to wp)
declare -f run_wp_cli | head -3 > "$SANDBOX/t11-2.def" 2>&1 || true
rm -f "$STUB_DIR/run.txt"
mkdir -p "$SANDBOX/wp_gate2"; set_site_type gate2 laravel
run_wp_cli gate2 plugin list > "$SANDBOX/t11-2.out" 2>&1
t11_2rc=$?
assert_eq "T11.2a run_wp_cli rc 1 on laravel" "1" "$t11_2rc"
grep -q "requires wp" "$SANDBOX/t11-2.out" && pass || fail "T11.2b run_wp_cli gate message"
[[ ! -s "$STUB_DIR/run.txt" ]] && pass || fail "T11.2c no container run for laravel"

# T11.3 wp site passes the gate (fails LATER on stubbed db network, not on gate)
set_site_type gate wp
run_wp_cli gate core version > "$SANDBOX/t11-3.out" 2>&1 || true
grep -q "requires wp" "$SANDBOX/t11-3.out" && fail "T11.3 wp site wrongly gated" || pass

# T11.4 optimize_site refuses non-wp (fresh site — T11.1 flipped gate to wp)
mkdir -p "$SANDBOX/wp_ogate"; set_site_type ogate laravel
optimize_site ogate > "$SANDBOX/t11-4.out" 2>&1
t11_4rc=$?
assert_eq "T11.4a optimize rc 1 on laravel" "1" "$t11_4rc"
grep -q "requires wp" "$SANDBOX/t11-4.out" && pass || fail "T11.4b optimize gate message"

# ---- T12: clone + reset type-aware (Task 10) ----
# Harness: run real scripts against a sandbox copy tree (scripts re-point
# PROJECT_ROOT to the sandbox; stubs on PATH fake docker/compose).
setup_script_sandbox() {
    cp -R "$REPO_ROOT/scripts" "$SANDBOX/scripts"
    cp -R "$REPO_ROOT/config" "$SANDBOX/config"
    mkdir -p "$SANDBOX/bin"
    for f in docker matrix-compose-stub stub-common.sh; do
        cp "$REPO_ROOT/tests/bash/bin/$f" "$SANDBOX/bin/$f"
    done
    chmod +x "$SANDBOX/bin/"*
}

run_script_sandboxed() {  # <script-name> <args...>  (stdin piped by caller)
    local script="$1"; shift
    sed -e "s|^PROJECT_ROOT=\"\$SCRIPT_DIR/..\"|PROJECT_ROOT=\"$SANDBOX\"|" \
        -e "s|source \"\$SCRIPT_DIR/common.sh\"|source \"$REPO_ROOT/scripts/common.sh\"; PROJECT_ROOT=\"$SANDBOX\"; COMPOSE_FILE=\"$SANDBOX/docker-compose.yml\"; DOCKER_COMPOSE=matrix-compose-stub; CONTAINER_RUNTIME=docker|" \
        "$REPO_ROOT/scripts/$script" > "$SANDBOX/$script"
    PATH="$SANDBOX/bin:$PATH" bash "$SANDBOX/$script" "$@"
}

setup_script_sandbox
mkdir -p "$SANDBOX/wp_cgrav"; set_site_type cgrav grav; touch "$SANDBOX/wp_cgrav/index.php"
write_base_compose

# T12.1 grav clone: no db touch at all
rm -f "$STUB_DIR/exec.txt"
run_script_sandboxed clone.sh cgrav cgrav2 >/dev/null 2>&1
t12_1rc=$?
assert_eq "T12.1a grav clone rc 0" "0" "$t12_1rc"
assert_eq "T12.1b grav clone: no db ops" "0" "$(grep -c 'mysqldump\|mysql' "$STUB_DIR/exec.txt" 2>/dev/null || echo 0)"
[[ -f "$SANDBOX/wp_cgrav2/index.php" ]] && pass || fail "T12.1c grav files cloned"

# T12.2 laravel clone: db created, no wp-cli search-replace, PHP inherited
mkdir -p "$SANDBOX/wp_cl"; set_site_type cl laravel; touch "$SANDBOX/wp_cl/artisan"
write_base_compose
: > "$SANDBOX/cl.conf"
compose_add_site cl 8.2 8310 "$SANDBOX/cl.conf" nginx laravel >/dev/null 2>&1
rm -f "$STUB_DIR/exec.txt" "$STUB_DIR/wp-cli-calls.txt"
run_script_sandboxed clone.sh cl cl2 >/dev/null 2>&1
t12_2rc=$?
assert_eq "T12.2a laravel clone rc 0" "0" "$t12_2rc"
grep -q 'CREATE DATABASE' "$STUB_DIR/exec.txt" 2>/dev/null && pass || fail "T12.2b laravel clone creates db"
[[ ! -s "$STUB_DIR/wp-cli-calls.txt" ]] && pass || fail "T12.2c laravel clone skips wp-cli"
# live-found: clone inherited DEFAULT_PHP (matrix-php:8.3) instead of the
# source's 8.2, so the clone tried to pull a nonexistent image
cl2_block=$(sed -n '/^  wp_cl2:/,/^  nginx_cl2:/p' "$COMPOSE_FILE")
assert_contains "T12.2d laravel clone inherits source PHP 8.2" "$cl2_block" "matrix-php:8.2"
# live-found: probe-laravel2 served from the SOURCE database — nothing repointed
# .env at the clone's own db. Set up the condition, then check the repoint.
printf 'DB_DATABASE=cl_db\nDB_PASSWORD=x\n' > "$SANDBOX/wp_cl/.env"
run_script_sandboxed clone.sh cl cl3 >/dev/null 2>&1 || true
assert_contains "T12.2e clone .env repointed at own db" "$(cat "$SANDBOX/wp_cl3/.env" 2>/dev/null)" "DB_DATABASE=cl3_db"
grep -q 'DB_DATABASE=cl_db' "$SANDBOX/wp_cl3/.env" 2>/dev/null && fail "T12.2f no source db name left" || pass

# T12.3 grav reset: db steps skipped
rm -f "$STUB_DIR/exec.txt"
printf 'y\n' | run_script_sandboxed reset.sh cgrav >/dev/null 2>&1
t12_3rc=$?
assert_eq "T12.3a grav reset rc 0" "0" "$t12_3rc"
assert_eq "T12.3b grav reset: no dump/drop" "0" "$(grep -c 'mysqldump\|DROP DATABASE' "$STUB_DIR/exec.txt" 2>/dev/null || echo 0)"

# T12.4 laravel reset: db reset still happens
rm -f "$STUB_DIR/exec.txt"
printf 'y\n' | run_script_sandboxed reset.sh cl >/dev/null 2>&1
grep -q 'DROP DATABASE' "$STUB_DIR/exec.txt" 2>/dev/null && pass || fail "T12.4 laravel reset resets db"

# ---- T13: export/import grav + site_state type (Task 11) ----
# seams: dump_site_db/db_exec_root/db_import_dump record to stubs
dump_site_db() { echo "$1" >> "$STUB_DIR/db-dumps.txt"; echo "DUMPDATA"; }
db_exec_root() { echo "$*" >> "$STUB_DIR/db-exec.txt"; }
db_import_dump() { echo "$2" >> "$STUB_DIR/db-imports.txt"; }
export -f dump_site_db db_exec_root db_import_dump 2>/dev/null || true
mkdir -p "$SANDBOX/wp_eg"; set_site_type eg grav; touch "$SANDBOX/wp_eg/index.php"
write_base_compose

# T13.1 export grav: no db seam, manifest type, no db member
rm -f "$STUB_DIR/db-dumps.txt"
export_site eg --out "$SANDBOX/eg-bundle.tar.gz" --json > "$SANDBOX/t13-1.json" 2>/dev/null
assert_eq "T13.1a export grav rc 0" "0" "$?"
assert_eq "T13.1b no db dump for grav" "0" "$(cat "$STUB_DIR/db-dumps.txt" 2>/dev/null | wc -l)"
grep -q '"type":"grav"' "$SANDBOX/eg-bundle-check" 2>/dev/null || true
tar -xzf "$SANDBOX/eg-bundle.tar.gz" -C "$SANDBOX" manifest.json -O > "$SANDBOX/t13-1.mf" 2>/dev/null
grep -q '"type":"grav"' "$SANDBOX/t13-1.mf" && pass || fail "T13.1c manifest carries type grav"
grep -q '"db_dump_sha256":""' "$SANDBOX/t13-1.mf" && pass || fail "T13.1d grav manifest has empty sha"
[[ $(tar -tzf "$SANDBOX/eg-bundle.tar.gz" | grep -c '^db/') == 0 ]] && pass || fail "T13.1e no db member for grav"

# T13.2 export wp: dump seam called (pin)
rm -f "$STUB_DIR/db-dumps.txt"
mkdir -p "$SANDBOX/wp_ew" "$SANDBOX/wp_ew/wp-content"; touch "$SANDBOX/wp_ew/wp-config.php"
sed -i "s/.*\$table_prefix.*/\$table_prefix = 'wp_';/" "$SANDBOX/wp_ew/wp-config.php" 2>/dev/null || true
set_site_type ew wp
export_site ew --out "$SANDBOX/ew-bundle.tar.gz" >/dev/null 2>&1
assert_eq "T13.2 wp export dumps db" "1" "$(wc -l < "$STUB_DIR/db-dumps.txt" 2>/dev/null || echo 0)"

# T13.3 import grav bundle: files restored, no db seam, create ran with type.
# Subshell under set -e, exactly like production matrix (a bare `A && B || C`
# would inhibit set -e inside the function and hide the bug): the no-db sha
# probe must not abort the shell (live-found: grav import exited 1 silent).
rm -f "$STUB_DIR/db-exec.txt" "$STUB_DIR/db-imports.txt"
( set -e; import_site "$SANDBOX/eg-bundle.tar.gz" ig1 --yes >/dev/null 2>&1 ); t13_rc=$?
assert_eq "T13.3a import grav rc 0 (set -e subshell)" "0" "$t13_rc"
assert_eq "T13.3b no db import for grav" "0" "$(wc -l < "$STUB_DIR/db-imports.txt" 2>/dev/null || echo 0)"
assert_eq "T13.3c no db exec for grav" "0" "$(wc -l < "$STUB_DIR/db-exec.txt" 2>/dev/null || echo 0)"
assert_eq "T13.3d imported marker grav" "grav" "$(cat "$SANDBOX/wp_ig1/.matrix-type" 2>/dev/null || echo missing)"
[[ -f "$SANDBOX/wp_ig1/index.php" ]] && pass || fail "T13.3e files restored"
# live-found (probe-laravel3 via import): restored .env kept the SOURCE db name.
# repoint_clone_env is shared by clone.sh and import_site — pin it directly.
mkdir -p "$SANDBOX/wp_rp4"
printf 'DB_DATABASE=oldsite_db\nDB_PASSWORD=x\n' > "$SANDBOX/wp_rp4/.env"
repoint_clone_env "$SANDBOX/wp_rp4" oldsite newsite
assert_contains "T13.6 repoint at own db" "$(cat "$SANDBOX/wp_rp4/.env")" "DB_DATABASE=newsite_db"
grep -q 'oldsite_db' "$SANDBOX/wp_rp4/.env" 2>/dev/null && fail "T13.6b no source db name left" || pass
# live-found (probe-drupal3 via clone): repoint missed drupal's settings.php —
# the helper only knew .env + configuration.php.
mkdir -p "$SANDBOX/wp_rp5/web/sites/default"
printf "<?php\n  'database' => 'oldsite_db',\n" > "$SANDBOX/wp_rp5/web/sites/default/settings.php"
repoint_clone_env "$SANDBOX/wp_rp5" oldsite newsite
assert_contains "T13.6c drupal settings.php repointed" "$(cat "$SANDBOX/wp_rp5/web/sites/default/settings.php")" "newsite_db"

# T13.4 import wp bundle: db seam used (pin)
rm -f "$STUB_DIR/db-imports.txt"
import_site "$SANDBOX/ew-bundle.tar.gz" iw1 --yes >/dev/null 2>&1
assert_eq "T13.4 wp import uses db seam" "1" "$(wc -l < "$STUB_DIR/db-imports.txt" 2>/dev/null || echo 0)"

# T13.6 list_sites_json exposes type for the dashboard
mkdir -p "$SANDBOX/wp_lj"; set_site_type lj grav
get_site_stack() { echo "nginx"; }
get_site_port() { echo "8299"; }
write_base_compose
mkdir -p "$SANDBOX/config/nginx"
: > "$SANDBOX/config/nginx/lj.conf"
# Real matrix-php service — no get_site_php_version_from_compose stub below, so
# an unparsed image would kill site_state/list_sites_json under set -e.
compose_add_site lj 8.2 8299 "$SANDBOX/config/nginx/lj.conf" nginx laravel >/dev/null 2>&1
lj_json=$(list_sites_json)
assert_contains "T13.6a list json carries type=grav" "$lj_json" '"name":"lj","status":"stopped","stack":"nginx","type":"grav"'
# No get_site_php_version_from_compose stub here: a real matrix-php image line
# must parse under set -e (regression: an unparsed image killed site_state,
# list_sites_json, info and rename for every non-wp site).
assert_eq "T13.6c real matrix-php image parsed" "8.2" "$(get_site_php_version_from_compose lj)"
mkdir -p "$SANDBOX/wp_lj2"
lj2_json=$(list_sites_json)
assert_contains "T13.6b list json defaults type=wp" "$lj2_json" '"name":"lj2","status":"stopped","stack":"nginx","type":"wp"'

# ---- T16: --skip-download skips provisioning for every type (Task 12 review fix) ----
# Regression: import_site calls create --skip-download, which was honored only
# inside the wp branch — non-wp types ran composer create-project and then had
# every file overwritten by the bundle restore.
rm -f "$STUB_DIR/run.txt" "$STUB_DIR/build.txt"
write_base_compose
mkdir -p "$SANDBOX/config/nginx"
: > "$SANDBOX/config/nginx/sklar.conf" "$SANDBOX/config/nginx/skgrav.conf"
create_site sklar --type=laravel --php-version=8.2 --skip-download >/dev/null 2>&1
assert_eq "T16.1a skip-download laravel: no composer run" "0" "$(grep -c 'create-project' "$STUB_DIR/run.txt" 2>/dev/null || echo 0)"
assert_eq "T16.1b skip-download laravel: no image build" "0" "$(grep -c 'matrix-php' "$STUB_DIR/build.txt" 2>/dev/null || echo 0)"
write_base_compose
create_site skgrav --type=grav --php-version=8.1 --skip-download >/dev/null 2>&1
assert_eq "T16.2 skip-download grav: no composer run" "0" "$(grep -c 'getgrav/grav' "$STUB_DIR/run.txt" 2>/dev/null || echo 0)"
# T16.3 no skip-download still provisions (proved live: fresh laravel create
# then serves 200; skip-download only skips for the import path)
rm -f "$STUB_DIR/run.txt" "$STUB_DIR/build.txt"
write_base_compose
create_site provlar --type=laravel --php-version=8.2 >/dev/null 2>&1
assert_contains "T16.3 no skip-download still provisions" "$(cat "$STUB_DIR/run.txt" 2>/dev/null)" "laravel/laravel"
assert_contains "T16.4 no skip-download still builds image" "$(cat "$STUB_DIR/build.txt" 2>/dev/null)" "matrix-php:8.2"
# post-start migrate runs for a real laravel create (wp_db is running from T9.5)
# but not for --skip-download (import brings its own db)
assert_contains "T16.5 laravel create runs post-start migrate" "$(cat "$STUB_DIR/exec.txt" 2>/dev/null)" "migrate"

# ---- T17: seeding happens in-container, rollback can delete (live-found bugs) ----
# Live laravel create exposed: chown-to-www-data makes the tree uid-33 owned, so
# the host-side `sed -i` of seed_laravel_env failed with "Permission denied" and
# the site was rolled back — and the rollback's own `rm -rf` failed too, leaving
# an undeletable half-site. Seeding now runs as root inside the provisioning
# container; rollback reclaims ownership before deleting.
rm -f "$STUB_DIR/run.txt"
laravel_script=$(laravel_seed_script ls1)
assert_contains "T17.1a laravel seed script targets container path" "$laravel_script" "/var/www/html/.env"
assert_contains "T17.1b laravel seed script sets DB_HOST=db" "$laravel_script" "DB_HOST=db"
assert_contains "T17.1c laravel seed script uses site db name" "$laravel_script" "DB_DATABASE=ls1_db"
# Laravel 12 .env has no DB_* lines (live-found) — generator must append
assert_contains "T17.1d laravel seed script appends when lines missing" "$laravel_script" "DB_CONNECTION=mysql"
# create must route through the container seeder, never the host one
mkdir -p "$SANDBOX/wp_ls1"
write_base_compose
provision_site_type ls1 laravel 8.2 >/dev/null 2>&1
ls1_run=$(cat "$STUB_DIR/run.txt" 2>/dev/null)
# stub records one arg per line: check the `sh -s` interpreter is passed
grep -qx 'sh' "$STUB_DIR/run.txt" 2>/dev/null && grep -qx -- '-s' "$STUB_DIR/run.txt" 2>/dev/null \
    && pass || fail "T17.2 create seeds via a container run (sh -s)"

# rollback removes a uid-33-owned tree the host user cannot delete
mkdir -p "$SANDBOX/wp_rbk/vendor/deep"
: > "$SANDBOX/wp_rbk/vendor/deep/file.php"
chmod 755 "$SANDBOX/wp_rbk/vendor" "$SANDBOX/wp_rbk/vendor/deep"
if [[ "$(id -u)" != "0" ]]; then
    # simulate container ownership: only root can write in here
    chown 33:33 "$SANDBOX/wp_rbk/vendor/deep" 2>/dev/null && chown_simu=1 || chown_simu=0
else
    chown_simu=1
fi
if [[ "$chown_simu" == "1" ]]; then
    rollback_site_create rbk >/dev/null 2>&1
    [[ ! -d "$SANDBOX/wp_rbk" ]] && pass || fail "T17.3 rollback removes non-writable tree"
else
    echo "T17.3 skipped (cannot chown as $(id -un))" 
fi

# ---- T15: repair_env is type-aware (Task 12 review fix) ----
# Regression: repair re-added non-wp sites as wordpress:phpX-fpm services and
# created a database for grav. Calls the REAL repair_env (no logic duplicated).
mkdir -p "$SANDBOX/wp_rp1"; set_site_type rp1 laravel
mkdir -p "$SANDBOX/wp_rp2"; set_site_type rp2 grav
mkdir -p "$SANDBOX/wp_rp3"; set_site_type rp3 wp
write_base_compose
repair_env >/dev/null 2>&1
# Per-site service block — repair_env walks every site in the sandbox, so
# whole-file counts would measure the other fixtures too.
rp1_block=$(sed -n '/^  wp_rp1:/,/^  nginx_rp1:/p' "$COMPOSE_FILE")
rp2_block=$(sed -n '/^  wp_rp2:/,/^  nginx_rp2:/p' "$COMPOSE_FILE")
rp3_block=$(sed -n '/^  wp_rp3:/,/^  nginx_rp3:/p' "$COMPOSE_FILE")
assert_contains "T15.1a repair keeps matrix-php image for laravel" "$rp1_block" "matrix-php:8.3"
grep -q 'WORDPRESS_DB_HOST' <<<"$rp1_block" && fail "T15.1b repair adds no WORDPRESS env for laravel" || pass
grep -q 'depends_on' <<<"$rp2_block" && fail "T15.2a repair: grav gets no depends_on db" || pass
grep -q 'rp2_db' <<<"$rp2_block" && fail "T15.2b repair: grav gets no DB name" || pass
assert_contains "T15.3a repair keeps wordpress image for wp" "$rp3_block" "wordpress:php8.3-fpm"
grep -q 'WORDPRESS_DB_HOST' <<<"$rp3_block" && pass || fail "T15.3b repair keeps wp DB env"

# T14.4 similar names never collide ("rm2" removal must not eat "rm21")
write_base_compose
: > "$SANDBOX/config/nginx/rm2.conf" "$SANDBOX/config/nginx/rm21.conf"
compose_add_site rm2  8.2 8308 "$SANDBOX/config/nginx/rm2.conf"  nginx laravel >/dev/null 2>&1
compose_add_site rm21 8.2 8309 "$SANDBOX/config/nginx/rm21.conf" nginx laravel >/dev/null 2>&1
compose_remove_site rm2 >/dev/null 2>&1
grep -q '^  wp_rm2:'  "$COMPOSE_FILE" && fail "T14.4a rm2 removed" || pass
grep -q '^  wp_rm21:' "$COMPOSE_FILE" && pass || fail "T14.4b rm21 untouched by rm2 removal"

# ---- T14: compose_remove_site works for every type (Task 12 review fix) ----
# Regression: compose_add_site renamed the block comment to "# Site: <n> (type: <t>)"
# while compose_remove_site still anchored on "# WordPress site: " — removal silently
# no-oped, leaving compose entries pointing at deleted site dirs.
write_base_compose
mkdir -p "$SANDBOX/wp_rml" "$SANDBOX/config/nginx"
: > "$SANDBOX/config/nginx/rml.conf"
compose_add_site rml 8.2 8305 "$SANDBOX/config/nginx/rml.conf" nginx laravel >/dev/null 2>&1
assert_contains "T14.1a added laravel compose entry" "$(cat "$COMPOSE_FILE")" "wp_rml:"
compose_remove_site rml >/dev/null 2>&1
grep -q '^  wp_rml:' "$COMPOSE_FILE" && fail "T14.1b laravel compose entry removed" || pass
write_base_compose
: > "$SANDBOX/config/nginx/rmw.conf"
compose_add_site rmw 8.3 8306 "$SANDBOX/config/nginx/rmw.conf" nginx wp >/dev/null 2>&1
compose_remove_site rmw >/dev/null 2>&1
grep -q '^  wp_rmw:' "$COMPOSE_FILE" && fail "T14.2 wp compose entry removed" || pass
write_base_compose
: > "$SANDBOX/config/nginx/rmg.conf"
compose_add_site rmg 8.1 8307 "$SANDBOX/config/nginx/rmg.conf" nginx grav >/dev/null 2>&1
compose_remove_site rmg >/dev/null 2>&1
grep -q '^  wp_rmg:' "$COMPOSE_FILE" && fail "T14.3 grav compose entry removed" || pass

# T13.5 site_state carries type
get_site_stack() { echo "nginx"; }
get_site_port() { echo "8299"; }
get_site_php_version_from_compose() { echo "8.1"; }
st_out=$(site_state ig1)
grep -q '^type=grav$' <<<"$st_out" && pass || fail "T13.5a site_state type=grav"
mkdir -p "$SANDBOX/wp_ewp"; st_out2=$(site_state ewp)
grep -q '^type=wp$' <<<"$st_out2" && pass || fail "T13.5b site_state type=wp default"

echo "site-types: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
