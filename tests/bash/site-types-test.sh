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
# T7 re-stubs it here for create_site flow tests.
provision_site_type() { echo "$@" >> "$STUB_DIR/provision-calls.txt"; return 0; }
export -f log_info log_success log_warning log_error run_wp_cli provision_site_type

# T7.1 laravel --skip-download → .matrix-type marker + provision called
write_base_compose
rm -f "$STUB_DIR/provision-calls.txt"
create_site t1 --type=laravel --skip-download >/dev/null 2>&1
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
assert_contains "T9.2a joomla downloads zip" "$joom_run" "downloads.joomla.org"
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
grav_execs=$(cat "$STUB_DIR/exec.txt" 2>/dev/null)
assert_eq "T9.5a grav create: no mysql exec" "0" "$(grep -c 'mysql' "$STUB_DIR/exec.txt" 2>/dev/null || echo 0)"
assert_eq "T9.5b grav marker" "grav" "$(cat "$SANDBOX/wp_gsite5/.matrix-type" 2>/dev/null || echo missing)"
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

echo "site-types: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
