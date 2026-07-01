#!/bin/bash
# compose-lib.sh — docker-compose.yml manipulation helpers
# All mutations are validated and atomic.

get_compose_file() {
    echo "$COMPOSE_FILE"
}

# Validate docker-compose.yml syntax
compose_validate() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_warning "Compose file not found — skipping validation"
        return 0
    fi
    if $DOCKER_COMPOSE config --quiet 2>/dev/null; then
        return 0
    fi
    local err
    err=$($DOCKER_COMPOSE config 2>&1 | head -5)
    log_error "Invalid docker-compose.yml: $err"
    return 1
}

# Atomic write: write to temp, validate, then rename
compose_atomic_write() {
    local src="$1"
    local dst="$2"
    local backup="${dst}.bak.$(date +%s)"

    cp "$dst" "$backup"
    cp "$src" "$dst"

    if compose_validate; then
        rm -f "$backup"
        return 0
    fi

    log_error "Validation failed — rolling back"
    mv "$backup" "$dst"
    return 1
}

# Add a site's service definitions to docker-compose.yml
# stack: nginx (default) or apache
compose_add_site() {
    local site_name="$1"
    local php_version="$2"
    local port="$3"
    local nginx_conf_path="$4"
    local stack="${5:-nginx}"

    if grep -q "^  wp_${site_name}:" "$COMPOSE_FILE" 2>/dev/null; then
        log_warning "Site '$site_name' already in docker-compose.yml"
        return 0
    fi

    local tmp
    tmp=$(mktemp)

    awk '/^volumes:/ {exit} {print}' "$COMPOSE_FILE" > "$tmp"

    if [[ "$stack" == "apache" ]]; then
        cat >> "$tmp" << EOF

  # WordPress site: $site_name (Apache — .htaccess parity with production)
  wp_$site_name:
    build:
      context: ./config/docker/wp-apache
      args:
        PHP_VERSION: ${php_version}
    image: wp-matrix-apache:${php_version}
    container_name: wp_$site_name
    restart: unless-stopped
    ports:
      - "$port:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: \${MYSQL_USER:-wp_user}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD:-wp_password}
      WORDPRESS_DB_NAME: ${site_name}_db
      WORDPRESS_DEBUG: \${WP_DEBUG:-true}
    volumes:
      - ./wp_$site_name:/var/www/html
    networks:
      - wp-net
    depends_on:
      db:
        condition: service_healthy
    mem_limit: 3g
    cpus: 1.0

EOF
    else
        cat >> "$tmp" << EOF

  # WordPress site: $site_name
  wp_$site_name:
    image: wordpress:php${php_version}-fpm
    container_name: wp_$site_name
    restart: unless-stopped
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: \${MYSQL_USER:-wp_user}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD:-wp_password}
      WORDPRESS_DB_NAME: ${site_name}_db
      WORDPRESS_DEBUG: \${WP_DEBUG:-true}
    volumes:
      - ./wp_$site_name:/var/www/html
    networks:
      - wp-net
    depends_on:
      db:
        condition: service_healthy
    mem_limit: 512m
    cpus: 0.5

  nginx_$site_name:
    image: nginx:alpine
    container_name: nginx_$site_name
    restart: unless-stopped
    ports:
      - "$port:80"
    depends_on:
      - wp_$site_name
    volumes:
      - ./wp_$site_name:/var/www/html:ro
      - $nginx_conf_path:/etc/nginx/conf.d/default.conf:ro
    networks:
      - wp-net
    mem_limit: 128m
    cpus: 0.25

EOF
    fi

    awk '/^volumes:/ {print; while(getline) print}' "$COMPOSE_FILE" >> "$tmp"

    compose_atomic_write "$tmp" "$COMPOSE_FILE"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

# Remove a site's service definitions from docker-compose.yml
compose_remove_site() {
    local site_name="$1"

    if [[ ! -f "$COMPOSE_FILE" ]]; then
        return 0
    fi

    if ! grep -q "wp_${site_name}:" "$COMPOSE_FILE" 2>/dev/null; then
        return 0
    fi

    local tmp
    tmp=$(mktemp)

    awk -v site="$site_name" '
    BEGIN { skip = 0 }
    skip {
        if (/^  # WordPress site: /) {
            skip = 0
            print
            next
        }
        if (/^[a-zA-Z]/ && !/^  /) {
            skip = 0
            print
            next
        }
        next
    }
    {
        if (/^  # WordPress site: / && index($0, site) > 0) {
            skip = 1
            next
        }
        print
    }
    ' "$COMPOSE_FILE" > "$tmp"

    compose_atomic_write "$tmp" "$COMPOSE_FILE"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

# Edit a value in docker-compose.yml for a specific site
compose_edit_value() {
    local site_name="$1"
    local service="$2"
    local key="$3"
    local value="$4"

    local block_prefix
    if [[ "$service" == "nginx" ]]; then
        block_prefix="nginx_${site_name}:"
    else
        block_prefix="wp_${site_name}:"
    fi

    local tmp
    tmp=$(mktemp)

    awk -v prefix="$block_prefix" -v key="$key" -v val="$value" '
    BEGIN { in_block = 0; replaced = 0 }
    /^[^ ]/ { in_block = 0 }
    index($0, prefix) > 0 { in_block = 1 }
    in_block && !replaced && index($0, key ":") > 0 {
        sub(key ":.*", key ": " val)
        replaced = 1
    }
    { print }
    ' "$COMPOSE_FILE" > "$tmp"

    compose_atomic_write "$tmp" "$COMPOSE_FILE"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

# Edit a site's PHP version in docker-compose.yml
compose_edit_php_version() {
    local site_name="$1"
    local php_version="$2"

    if [[ "$(get_site_stack "$site_name")" == "apache" ]]; then
        local tmp
        tmp=$(mktemp)
        awk -v site="wp_${site_name}:" -v ver="$php_version" '
        BEGIN { in_block = 0 }
        /^[^ ]/ { in_block = 0 }
        index($0, site) > 0 { in_block = 1 }
        in_block && /^\s+image:/ {
            sub(/image:.*/, "image: wp-matrix-apache:" ver)
        }
        in_block && /^\s+PHP_VERSION:/ {
            sub(/PHP_VERSION:.*/, "PHP_VERSION: " ver)
        }
        { print }
        ' "$COMPOSE_FILE" > "$tmp"
        compose_atomic_write "$tmp" "$COMPOSE_FILE"
        local rc=$?
        rm -f "$tmp"
        return $rc
    fi

    compose_edit_value "$site_name" "wp" "image" "wordpress:php${php_version}-fpm"
}

# Edit a site's port in docker-compose.yml
compose_edit_port() {
    local site_name="$1"
    local port="$2"

    local block
    if site_has_nginx "$site_name"; then
        block="nginx_${site_name}:"
    else
        block="wp_${site_name}:"
    fi

    local tmp
    tmp=$(mktemp)

    awk -v site="$block" -v newport="\"${port}:80\"" '
    /^[^ ]/ { in_block = 0 }
    index($0, site) > 0 { in_block = 1 }
    in_block && /"[0-9]+:80"/ {
        gsub(/"[0-9]+:80"/, newport)
    }
    { print }
    ' "$COMPOSE_FILE" > "$tmp"

    compose_atomic_write "$tmp" "$COMPOSE_FILE"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

# Edit a site's memory limit for wp (and nginx when present)
compose_edit_memory() {
    local site_name="$1"
    local wp_mem="$2"

    local nginx_mem
    local num
    num=$(echo "$wp_mem" | sed 's/^\([0-9]*\).*/\1/')
    local unit
    unit=$(echo "$wp_mem" | sed 's/^[0-9]*//I')

    if [[ "$unit" == "G" || "$unit" == "g" ]]; then
        nginx_mem=$((num / 2))
        [[ $nginx_mem -lt 128 ]] && nginx_mem=128
        nginx_mem="${nginx_mem}m"
    elif [[ "$unit" == "M" || "$unit" == "m" ]]; then
        nginx_mem=$((num / 2))
        [[ $nginx_mem -lt 128 ]] && nginx_mem=128
        nginx_mem="${nginx_mem}m"
    else
        nginx_mem="128m"
    fi

    compose_edit_value "$site_name" "wp" "mem_limit" "$wp_mem" || return 1
    if site_has_nginx "$site_name"; then
        compose_edit_value "$site_name" "nginx" "mem_limit" "$nginx_mem"
    fi
}

# Edit a site's CPU limit for wp (and nginx when present)
compose_edit_cpu() {
    local site_name="$1"
    local wp_cpu="$2"

    local nginx_cpu
    nginx_cpu=$(echo "$wp_cpu" | awk '{print $1/2}')
    local min_cpu
    min_cpu=$(echo "$nginx_cpu < 0.25" | bc -l 2>/dev/null || echo 0)
    [[ "$min_cpu" == "1" ]] && nginx_cpu=0.25

    compose_edit_value "$site_name" "wp" "cpus" "$wp_cpu" || return 1
    if site_has_nginx "$site_name"; then
        compose_edit_value "$site_name" "nginx" "cpus" "$nginx_cpu"
    fi
}
