#!/bin/bash
# helpers.sh — Shared helper functions for wordpress-matrix
# Sourced by both matrix and common.sh.
# All functions depend on $PROJECT_ROOT, $COMPOSE_FILE, $CONTAINER_RUNTIME being set.

# Detect host LAN IP for user-facing URLs so other devices on the network can
# connect. Sourced by both `matrix` and the scripts/*.sh subprocess scripts via
# common.sh, so HOST_IP is available everywhere.
get_lan_ip() {
    local ip=""
    if [[ "$(uname)" == "Darwin" ]]; then
        ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
    else
        ip=$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}' 2>/dev/null || \
             hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    echo "${ip:-localhost}"
}
HOST_IP=$(get_lan_ip)

# --- Container state primitives (single home; used by matrix and scripts/*.sh) ---

compose_ps_names() {
    local names
    names=$($DOCKER_COMPOSE ps --format "{{.Names}}" 2>/dev/null) || true
    if [[ -z "$names" ]]; then
        names=$($DOCKER_COMPOSE ps 2>/dev/null | awk 'NR>1 {print $1}' | grep -v '^---$' || true)
    fi
    echo "$names"
}

container_is_running() {
    local container_name="${1:-}"
    [[ -n "$container_name" ]] && $CONTAINER_RUNTIME ps --format "{{.Names}}" 2>/dev/null | grep -q "^${container_name}$"
}

compose_or_container_running() {
    local container_name="${1:-}"
    compose_ps_names 2>/dev/null | grep -q "^${container_name}$" || container_is_running "$container_name"
}

get_sites() {
    local sites=()
    for dir in "$PROJECT_ROOT"/wp_*; do
        if [[ -d "$dir" ]]; then
            local base_dir="${dir##*/}"
            local site_name="${base_dir#wp_}"
            if [[ -n "$site_name" && "$site_name" != "content" ]]; then
                sites+=("$site_name")
            fi
        fi
    done
    if ((${#sites[@]})); then
        printf '%s\n' "${sites[@]}" | sort -u
    fi
}

site_exists() {
    local site_name="${1:-}"
    [[ -d "$PROJECT_ROOT/wp_$site_name" ]]
}

get_next_port() {
    local max_port=8200
    if [[ -f "$COMPOSE_FILE" ]]; then
        local ports
        ports=$(grep -oE '^\s*-\s*"[0-9]+:80"' "$COMPOSE_FILE" 2>/dev/null | \
            grep -oE '[0-9]+:80' | grep -oE '^[0-9]+' | sort -nr)
        if [[ -n "$ports" ]]; then
            max_port=$(echo "$ports" | head -n 1)
        fi
    fi
    max_port=$((max_port + 1))
    while port_in_use "$max_port"; do
        max_port=$((max_port + 1))
    done
    echo "$max_port"
}

port_in_use() {
    local port="${1:-}"
    [[ -z "$port" ]] && return 1
    if command -v lsof >/dev/null 2>&1 && lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
        return 0
    fi
    if command -v ss >/dev/null 2>&1 && ss -tln 2>/dev/null | grep -q ":$port "; then
        return 0
    fi
    $CONTAINER_RUNTIME ps --format "{{.Ports}}" 2>/dev/null | grep -q ":$port->"
}

get_db_network() {
    $CONTAINER_RUNTIME inspect wp_db --format '{{range $name, $_ := .NetworkSettings.Networks}}{{println $name}}{{end}}' 2>/dev/null | head -1
}

run_wp_cli() {
    local site="${1:-}"
    shift 2>/dev/null || true

    validate_site_name "$site" || return 1
    if ! site_exists "$site"; then
        log_error "Site '$site' not found"
        return 1
    fi
    if [[ $# -eq 0 ]]; then
        log_error "Usage: run_wp_cli <site> <wp-cli arguments>"
        return 1
    fi

    local db_network
    db_network=$(get_db_network)
    if [[ -z "$db_network" ]]; then
        log_error "Could not determine database container network"
        return 1
    fi

    $CONTAINER_RUNTIME run --rm \
        -v "$PROJECT_ROOT":/var/www/html:rw \
        -w /var/www/html \
        --network "$db_network" \
        -e WORDPRESS_DB_HOST=db:3306 \
        -e WORDPRESS_DB_USER="${MYSQL_USER:-wp_user}" \
        -e WORDPRESS_DB_PASSWORD="${MYSQL_PASSWORD:-wp_password}" \
        -e WORDPRESS_DB_NAME="${site}_db" \
        wordpress:cli --path="/var/www/html/wp_$site" "$@"
}

# --- Site stack helpers (nginx + PHP-FPM vs Apache + PHP-FPM) ---

# Canonical "is this site defined in docker-compose.yml" predicate (anchored).
site_in_compose() {
    local site="${1:-}"
    [[ -n "$site" && -f "$COMPOSE_FILE" ]] && grep -q "^  wp_${site}:" "$COMPOSE_FILE" 2>/dev/null
}

site_has_nginx() {
    local site="${1:-}"
    [[ -n "$site" && -f "$COMPOSE_FILE" ]] && grep -q "^  nginx_${site}:" "$COMPOSE_FILE" 2>/dev/null
}

get_site_stack() {
    local site="${1:-}"
    if [[ -z "$site" ]] || ! site_in_compose "$site"; then
        echo "nginx"
        return
    fi
    if site_has_nginx "$site"; then
        echo "nginx"
        return
    fi
    if grep -q "^  wp_${site}:" "$COMPOSE_FILE" 2>/dev/null; then
        if grep -A 40 "^  wp_${site}:" "$COMPOSE_FILE" | grep -qE 'wp-matrix-apache|docker/wp-apache'; then
            echo "apache"
            return
        fi
        if grep -A 40 "^  wp_${site}:" "$COMPOSE_FILE" | grep -qE '^\s+ports:'; then
            echo "apache"
            return
        fi
    fi
    echo "nginx"
}

# --- Site state: one interface over compose metadata + live containers ---
# Contract: running = wp_<site> container up (anchored match);
#           port    = compose port, else live nginx port, else live wp port;
#           php     = compose image only; stack = compose-derived, default nginx;
#           present = service defined in docker-compose.yml.
site_state() {
    local site="${1:-}"
    local present=0 running=0 port="" php="" stack=""

    site_in_compose "$site" && present=1
    compose_or_container_running "wp_$site" && running=1
    port=$(get_site_port "$site")
    php=$(get_site_php_version_from_compose "$site")
    stack=$(get_site_stack "$site")

    echo "present=$present"
    echo "running=$running"
    echo "port=$port"
    echo "php=$php"
    echo "stack=$stack"
}

compose_site_service_names() {
    local site="${1:-}"
    if site_has_nginx "$site"; then
        echo "wp_${site} nginx_${site}"
    else
        echo "wp_${site}"
    fi
}

get_site_port_from_compose() {
    local site="${1:-}"
    local block=""
    if [[ -z "$site" || ! -f "$COMPOSE_FILE" ]]; then
        return
    fi
    if site_has_nginx "$site"; then
        block="nginx_${site}"
    else
        block="wp_${site}"
    fi
    grep -A 25 "^  ${block}:" "$COMPOSE_FILE" 2>/dev/null | \
        grep -E '^\s*-\s*"[0-9]+:80"' | grep -oE '[0-9]+' | head -1
}

get_site_php_version_from_compose() {
    local site="${1:-}"
    local image_line=""
    if [[ -z "$site" || ! -f "$COMPOSE_FILE" ]]; then
        return
    fi
    image_line=$(grep -A 20 "^  wp_${site}:" "$COMPOSE_FILE" 2>/dev/null | grep -E '^\s+image:' | head -1 || true)
    if [[ -z "$image_line" ]]; then
        return
    fi
    if [[ "$image_line" == *wp-matrix-apache* ]]; then
        echo "$image_line" | grep -oE '[0-9]+\.[0-9]+' | head -1
    else
        echo "$image_line" | grep -oE 'php[0-9.]+' | sed 's/php//'
    fi
}

get_site_port() {
    local site="${1:-}"
    local port=""
    port=$(get_site_port_from_compose "$site")
    if [[ -z "$port" ]]; then
        # Live nginx probe works with or without compose metadata.
        port=$($CONTAINER_RUNTIME port "nginx_$site" 2>/dev/null | grep '80/tcp' | head -1 | sed 's/.*://' | tr -d ' ' || true)
    fi
    if [[ -z "$port" ]]; then
        port=$($CONTAINER_RUNTIME port "wp_$site" 2>/dev/null | grep '80/tcp' | head -1 | sed 's/.*://' | tr -d ' ' || true)
    fi
    echo "$port"
}

matrix_site_build_if_apache() {
    local site="${1:-}"
    if [[ "$(get_site_stack "$site")" == "apache" ]]; then
        local php_version
        php_version=$(get_site_php_version_from_compose "$site")
        [[ -z "$php_version" ]] && php_version="${DEFAULT_PHP_VERSION:-8.3}"
        if docker image inspect "wp-matrix-apache:${php_version}" >/dev/null 2>&1; then
            log_info "Reusing existing Apache image 'wp-matrix-apache:${php_version}' for '$site'."
            return 0
        fi
        log_info "Building Apache image for '$site'..."
        $DOCKER_COMPOSE build "wp_${site}"
    fi
}

matrix_site_up() {
    local site="${1:-}"
    local services
    services=$(compose_site_service_names "$site")
    # shellcheck disable=SC2086
    $DOCKER_COMPOSE up -d $services 2>/dev/null || true
}

matrix_site_stop() {
    local site="${1:-}"
    local services
    services=$(compose_site_service_names "$site")
    # shellcheck disable=SC2086
    $DOCKER_COMPOSE stop $services 2>/dev/null || true
}

matrix_site_restart() {
    local site="${1:-}"
    local services
    services=$(compose_site_service_names "$site")
    # shellcheck disable=SC2086
    $DOCKER_COMPOSE up -d $services 2>/dev/null || \
    $CONTAINER_RUNTIME restart $services 2>/dev/null || true
}

matrix_site_rm_containers() {
    local site="${1:-}"
    local services
    services=$(compose_site_service_names "$site")
    # shellcheck disable=SC2086
    $DOCKER_COMPOSE rm -f $services 2>/dev/null || true
    # shellcheck disable=SC2086
    $CONTAINER_RUNTIME rm -f $services 2>/dev/null || true
}

# --- WP version helpers (Phase 7) ---

# Validate a WP version string: dotted x.y or 'latest'.
validate_wp_version() {
    local v="${1:-}"
    [[ "$v" == "latest" ]] && return 0
    [[ "$v" =~ ^[0-9]+\.[0-9]+$ ]] || return 1
    # Accept 6.4, 6.5, 6.6 (major 6, minor 4+)
    local major minor
    major=$(echo "$v" | cut -d. -f1)
    minor=$(echo "$v" | cut -d. -f2)
    [[ "$major" -eq 6 && "$minor" -ge 4 ]] && return 0
    return 1
}

# Resolve 'latest' to a concrete version; pass through valid concrete versions.
resolve_wp_version() {
    local v="${1:-latest}"
    [[ "$v" == "latest" ]] && echo "6.6" || echo "$v"
}

# Fetch WordPress core for a given version into a target directory.
# Uses MATRIX_WP_FETCH_CMD env override (default: curl from wordpress.org).
# Usage: wp_fetch_core <version> <target_dir>
wp_fetch_core() {
    local version="${1:-}"
    local target="${2:-}"
    [[ -z "$version" || -z "$target" ]] && return 1
    local url="https://wordpress.org/wordpress-${version}.tar.gz"
    if [[ -n "${MATRIX_WP_FETCH_CMD:-}" ]]; then
        # shellcheck disable=SC2086
        ${MATRIX_WP_FETCH_CMD} "$url" "$target"
    else
        curl -sL "$url" | tar -xz -C "$target" --strip-components=1
    fi
}

# Read the WP version from a site's version.php.
# Usage: site_wp_version <site>
site_wp_version() {
    local site="${1:-}"
    local version_file="$PROJECT_ROOT/wp_$site/wp-includes/version.php"
    if [[ -f "$version_file" ]]; then
        sed -n "s/.*\$wp_version = '\([^']*\)'.*/\1/p" "$version_file" 2>/dev/null
    fi
}

# Compatibility test matrix: run checks across WP versions for a site.
# Usage: compat_test <site> [--wp-versions=6.4,6.5] [--json]
compat_test() {
    local site="${1:-}"
    local wp_versions="6.4,6.5"
    local json=false
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --wp-versions=*) wp_versions="${1#*=}"; shift ;;
            --json) json=true; shift ;;
            *) shift ;;
        esac
    done
    [[ -z "$site" ]] && return 1

    local php_version
    php_version=$(grep -E '^image: wordpress:php' "$PROJECT_ROOT/docker-compose.yml" | head -1 | sed 's/.*php\([0-9]\.[0-9]\)-fpm.*/\1/')
    [[ -z "$php_version" ]] && php_version="8.3"

    # Split AFTER IFS is in effect: `local IFS=',' x=($v)` expands with the
    # old IFS in the same simple-command, so split on a separate line.
    local versions
    IFS=',' read -ra versions <<< "$wp_versions"
    local rows=()
    [[ "$json" != true ]] && printf "%-12s %-5s %-5s %-6s %s\n" "site" "php" "wp" "result" "detail"
    for wp in "${versions[@]}"; do
        local combo_name="wp_${site}_t${php_version//./}${wp//./}"
        local result="ok"
        local detail=""

        # Ephemeral setup: create temp dir, fetch core, run verify-checksums
        local temp_dir
        temp_dir=$(mktemp -d -t "${combo_name}.XXXXXX")

        if ! wp_fetch_core "$wp" "$temp_dir" >/dev/null 2>&1; then
            result="fail"
            detail="fetch failed"
        elif ! run_wp_cli "$combo_name" core verify-checksums >/dev/null 2>&1; then
            result="fail"
            detail="checksums failed"
        fi
        rm -rf "$temp_dir"

        # Cleanup: remove any ephemeral containers
        $CONTAINER_RUNTIME rm -f "$combo_name" 2>/dev/null || true

        if [[ "$json" == true ]]; then
            rows+=("{\"site\":\"$site\",\"php\":\"$php_version\",\"wp\":\"$wp\",\"result\":\"$result\"}")
        else
            printf "%-12s %-5s %-5s %-6s %s\n" "$site" "$php_version" "$wp" "$result" "$detail"
        fi
    done

    if [[ "$json" == true ]]; then
        local joined
        joined=$(IFS=,; echo "${rows[*]}")
        output_json "[$joined]"
    fi
}
