#!/usr/bin/env bash
# site-types-lib.sh — multi-PHP-stack type registry for matrix.
# Spec: docs/superpowers/specs/2026-10-13-multi-php-stack-support-design.md
# Types, PHP floors, webroots, DB usage, runtime images, .matrix-type marker.

SITE_TYPES=(wp laravel symfony drupal joomla grav)

validate_site_type() {
    local type="${1:-}"
    case "$type" in
        wp|laravel|symfony|drupal|joomla|grav) return 0 ;;
        *) return 1 ;;
    esac
}

site_type_min_php() {
    local type="${1:-}"
    case "$type" in
        wp) echo "7.4" ;;
        joomla|grav) echo "8.1" ;;
        laravel|symfony) echo "8.2" ;;
        drupal) echo "8.3" ;;
        *) return 1 ;;
    esac
}

site_type_webroot() {
    local type="${1:-}"
    case "$type" in
        laravel|symfony) echo "public" ;;
        drupal) echo "web" ;;
        wp|joomla|grav) echo "" ;;
        *) return 1 ;;
    esac
}

site_type_uses_db() {
    local type="${1:-}"
    [[ "$type" == "grav" ]] && return 1
    validate_site_type "$type"
}

site_type_runtime_image() {
    local type="${1:-}" php="${2:-}"
    if [[ "$type" == "wp" ]]; then
        echo "wordpress:php${php}-fpm"
    else
        echo "matrix-php:${php}"
    fi
}

get_site_type() {
    local site="${1:-}"
    local marker="$PROJECT_ROOT/wp_${site}/.matrix-type"
    if [[ -f "$marker" ]]; then
        cat "$marker"
    else
        echo "wp"
    fi
}

set_site_type() {
    local site="${1:-}" type="${2:-}"
    validate_site_type "$type" || return 1
    echo "$type" > "$PROJECT_ROOT/wp_${site}/.matrix-type"
}

# php_at_least <have> <floor> — version-aware PHP floor comparison (sort -V)
php_at_least() {
    local have="${1:-}" floor="${2:-}"
    [[ "$(printf '%s\n' "$floor" "$have" | sort -V | head -1)" == "$floor" ]]
}

# build_site_image <php> — build matrix-php:<php> only when not present.
# Mirrors matrix_site_build_if_apache: image build is idempotent per version.
build_site_image() {
    local php="${1:-}"
    local image="matrix-php:${php}"
    if [[ -n "$($CONTAINER_RUNTIME images -q "$image" 2>/dev/null)" ]]; then
        return 0
    fi
    $CONTAINER_RUNTIME build --build-arg PHP_VERSION="$php" -t "$image" \
        "$PROJECT_ROOT/config/docker/php-site"
}
