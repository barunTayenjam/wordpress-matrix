#!/bin/bash
set -euo pipefail

# WordPress Development Environment Entrypoint
echo "🚀 Starting WordPress Development Environment..."

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    sleep 1
done
echo "✅ Database connection established"

# Run original WordPress entrypoint
if [ -f /usr/local/bin/docker-entrypoint.sh ]; then
    source /usr/local/bin/docker-entrypoint.sh
fi

# Install WordPress if not already installed
if ! wp core is-installed --allow-root --path=/var/www/html 2>/dev/null; then
    echo "📦 Installing WordPress..."
    
    # Download WordPress if not present
    if [ ! -f /var/www/html/wp-config.php ]; then
        wp core download --allow-root --path=/var/www/html --force
    fi
    
    # Create wp-config.php if not present
    if [ ! -f /var/www/html/wp-config.php ]; then
        wp config create \
            --dbname="$WORDPRESS_DB_NAME" \
            --dbuser="$WORDPRESS_DB_USER" \
            --dbpass="$WORDPRESS_DB_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --allow-root \
            --path=/var/www/html \
            --extra-php <<PHP
// Redis Object Cache
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_CACHE_KEY_SALT', '$WORDPRESS_DB_NAME');

// Development Settings
define('WP_ENVIRONMENT_TYPE', 'development');
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);
define('DISALLOW_FILE_EDIT', false);

// Debug Settings
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', true);
define('SCRIPT_DEBUG', true);
define('SAVEQUERIES', true);

// Memory Settings
define('WP_MEMORY_LIMIT', '512M');

// Security
define('FORCE_SSL_ADMIN', false);
define('WP_POST_REVISIONS', 10);
define('AUTOSAVE_INTERVAL', 300);

// Performance
define('WP_CACHE', true);
define('COMPRESS_CSS', true);
define('COMPRESS_SCRIPTS', true);
define('CONCATENATE_SCRIPTS', false);
define('ENFORCE_GZIP', true);
PHP
    fi
    
    # Install WordPress
    wp core install \
        --url="http://localhost" \
        --title="WordPress Development Site" \
        --admin_user="admin" \
        --admin_password="admin" \
        --admin_email="admin@localhost" \
        --allow-root \
        --path=/var/www/html
    
    echo "✅ WordPress installed successfully"
fi

# Install and activate essential plugins
echo "🔌 Installing essential development plugins..."

# Redis Object Cache
if ! wp plugin is-installed redis-cache --allow-root --path=/var/www/html; then
    wp plugin install redis-cache --activate --allow-root --path=/var/www/html
fi

# Query Monitor
if ! wp plugin is-installed query-monitor --allow-root --path=/var/www/html; then
    wp plugin install query-monitor --activate --allow-root --path=/var/www/html
fi

# Debug Bar
if ! wp plugin is-installed debug-bar --allow-root --path=/var/www/html; then
    wp plugin install debug-bar --activate --allow-root --path=/var/www/html
fi

# Developer Tools
if ! wp plugin is-installed developer --allow-root --path=/var/www/html; then
    wp plugin install developer --activate --allow-root --path=/var/www/html || true
fi

# Set proper permissions
echo "🔒 Setting proper file permissions..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chmod 600 /var/www/html/wp-config.php

# Create log directories
mkdir -p /var/log/nginx /var/log/php /var/log/supervisor /var/log/wordpress
chown -R www-data:www-data /var/log/nginx /var/log/php /var/log/wordpress

# Optimize WordPress
echo "⚡ Optimizing WordPress..."
/usr/local/bin/wp-optimize

echo "🎉 WordPress Development Environment is ready!"
echo "📊 Access your site at: http://wordpress1.127.0.0.1.nip.io"
echo "🔧 Admin credentials: admin/admin"

# Execute the main command
exec "$@"