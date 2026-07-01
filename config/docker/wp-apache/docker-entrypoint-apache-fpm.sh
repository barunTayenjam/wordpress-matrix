#!/bin/bash
set -euo pipefail

# WordPress entrypoint handles db wait, permissions, etc.
if [[ -f /usr/local/bin/docker-entrypoint.sh ]]; then
    /usr/local/bin/docker-entrypoint.sh php-fpm -t
fi

mkdir -p /run/php
chown www-data:www-data /run/php

# Start PHP-FPM (background), then Apache (foreground).
if [[ -f /usr/local/bin/docker-entrypoint.sh ]]; then
    /usr/local/bin/docker-entrypoint.sh php-fpm -D
else
    php-fpm -D
fi

exec /usr/sbin/apache2ctl -D FOREGROUND
