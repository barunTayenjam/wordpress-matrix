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

site_has_nginx() {
    local site="${1:-}"
    [[ -n "$site" && -f "$COMPOSE_FILE" ]] && grep -q "^  nginx_${site}:" "$COMPOSE_FILE" 2>/dev/null
}

get_site_stack() {
    local site="${1:-}"
    if [[ -z "$site" || ! -f "$COMPOSE_FILE" ]]; then
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
        if site_has_nginx "$site"; then
            port=$($CONTAINER_RUNTIME port "nginx_$site" 2>/dev/null | grep '80/tcp' | head -1 | sed 's/.*://' | tr -d ' ' || true)
        fi
    fi
    if [[ -z "$port" ]]; then
        port=$($CONTAINER_RUNTIME port "wp_$site" 2>/dev/null | grep '80/tcp' | head -1 | sed 's/.*://' | tr -d ' ' || true)
    fi
    echo "$port"
}

matrix_site_build_if_apache() {
    local site="${1:-}"
    if [[ "$(get_site_stack "$site")" == "apache" ]]; then
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
