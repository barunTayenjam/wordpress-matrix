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

# generate_nginx_conf <site> <type> — write config/nginx/<site>.conf with the
# type's webroot. Extracted from create_site's inline heredoc (multi-stack spec).
generate_nginx_conf() {
    local site="${1:-}"
    local type="${2:-wp}"
    local webroot
    webroot=$(site_type_webroot "$type")
    [[ -n "$webroot" ]] && webroot="/${webroot}"
    local conf_dir="$PROJECT_ROOT/config/nginx"
    [[ -d "$conf_dir" ]] || mkdir -p "$conf_dir"
    cat > "$conf_dir/$site.conf" << EOF
server {
    listen 80;
    server_name _;
    root /var/www/html${webroot};
    index index.php index.html;
    client_max_body_size 25m;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass wp_$site:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;

        # Increase buffer sizes to handle large headers
        fastcgi_buffer_size 32k;
        fastcgi_buffers 16 16k;
        fastcgi_busy_buffers_size 32k;
    }

    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }
}
EOF
}
