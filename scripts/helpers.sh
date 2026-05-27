#!/bin/bash
# helpers.sh — Shared helper functions for wordpress-matrix
# Sourced by both matrix and common.sh.
# All functions depend on $PROJECT_ROOT, $COMPOSE_FILE, $CONTAINER_RUNTIME being set.

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
    printf '%s\n' "${sites[@]}" | sort -u
}

site_exists() {
    local site_name="${1:-}"
    [[ -d "$PROJECT_ROOT/wp_$site_name" ]]
}

get_next_port() {
    local max_port=8100
    if [[ -f "$COMPOSE_FILE" ]]; then
        local ports
        ports=$(grep -oE '^\s*-\s*"[0-9]+:80"' "$COMPOSE_FILE" 2>/dev/null | \
            grep -oE '[0-9]+:80' | grep -oE '^[0-9]+' | sort -nr)
        if [[ -n "$ports" ]]; then
            max_port=$(echo "$ports" | head -n 1)
        fi
    fi
    ((max_port++))
    while port_in_use "$max_port"; do
        ((max_port++))
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
