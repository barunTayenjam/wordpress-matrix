#!/bin/bash
set -euxo pipefail

echo "DEBUG: Starting docker-entrypoint-custom.sh"

# Call the original WordPress entrypoint script
/usr/local/bin/docker-entrypoint.sh "$@"

# WordPress Development Environment Entrypoint
echo "🚀 Starting WordPress Development Environment..."

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    sleep 1
done
echo "✅ Database connection established"

# Install WordPress if not already installed
if ! wp core is-installed --allow-root --path=/var/www/html 2> /tmp/wp_is_installed_stderr.log; then
    echo "DEBUG: WordPress is NOT installed or check failed. Stderr:"
    cat /tmp/wp_is_installed_stderr.log
    echo "📦 Installing WordPress..."
    
    # Download WordPress if not present
    if [ ! -f /var/www/html/wp-config.php ]; then
        echo "DEBUG: Attempting wp core download..."
        wp core download --allow-root --path=/var/www/html --force 2> /tmp/wp_download_stderr.log
        WP_DOWNLOAD_EXIT_CODE=$?
        echo "DEBUG: wp core download finished with exit code: ${WP_DOWNLOAD_EXIT_CODE}. Stderr:"
        cat /tmp/wp_download_stderr.log
        if [ ${WP_DOWNLOAD_EXIT_CODE} -ne 0 ]; then
            echo "Error: WordPress download failed. Exiting."
            exit ${WP_DOWNLOAD_EXIT_CODE}
        fi
    else
        echo "wp-config.php already exists."
    fi
    ls -la /var/www/html/wp-config.php
    
    # Create wp-config.php if not present
    if [ ! -f /var/www/html/wp-config.php ]; then
        echo "DEBUG: Attempting wp config create..."
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
        WP_CONFIG_EXIT_CODE=$?
        echo "DEBUG: wp config create finished with exit code: ${WP_CONFIG_EXIT_CODE}. Stderr:"
        cat /tmp/wp_config_stderr.log
        if [ ${WP_CONFIG_EXIT_CODE} -ne 0 ]; then
            echo "Error: wp-config.php creation failed. Exiting."
            exit ${WP_CONFIG_EXIT_CODE}
        fi
    fi
    
    # Install WordPress
    echo "Attempting WordPress core install..."
    echo "DEBUG: Attempting wp core install..."
    wp core install \
        --url="http://localhost" \
        --title="WordPress Development Site" \
        --admin_user="admin" \
        --admin_password="admin" \
        --admin_email="admin@localhost" \
        --allow-root \
        --path=/var/www/html 2> /tmp/wp_install_stderr.log
    WP_INSTALL_EXIT_CODE=$?
    echo "DEBUG: wp core install finished with exit code: ${WP_INSTALL_EXIT_CODE}. Stderr:"
    cat /tmp/wp_install_stderr.log
    if [ ${WP_INSTALL_EXIT_CODE} -ne 0 ]; then
        echo "Error: WordPress installation failed. Check logs for details."
        exit ${WP_INSTALL_EXIT_CODE}
    fi
    echo "✅ WordPress installed successfully"
fi

# Install and activate essential plugins
echo "🔌 Installing essential development plugins..."

# Redis Object Cache
echo "DEBUG: Installing redis-cache plugin..."
if ! wp plugin is-installed redis-cache --allow-root --path=/var/www/html 2> /tmp/wp_plugin_redis_stderr.log; then
    wp plugin install redis-cache --activate --allow-root --path=/var/www/html 2>> /tmp/wp_plugin_redis_stderr.log
    WP_PLUGIN_REDIS_EXIT_CODE=$?
    echo "DEBUG: redis-cache plugin install finished with exit code: ${WP_PLUGIN_REDIS_EXIT_CODE}. Stderr:"
    cat /tmp/wp_plugin_redis_stderr.log
fi

# Query Monitor
echo "DEBUG: Installing query-monitor plugin..."
if ! wp plugin is-installed query-monitor --allow-root --path=/var/www/html 2> /tmp/wp_plugin_query_stderr.log; then
    wp plugin install query-monitor --activate --allow-root --path=/var/www/html 2>> /tmp/wp_plugin_query_stderr.log
    WP_PLUGIN_QUERY_EXIT_CODE=$?
    echo "DEBUG: query-monitor plugin install finished with exit code: ${WP_PLUGIN_QUERY_EXIT_CODE}. Stderr:"
    cat /tmp/wp_plugin_query_stderr.log
fi

# Debug Bar
echo "DEBUG: Installing debug-bar plugin..."
if ! wp plugin is-installed debug-bar --allow-root --path=/var/www/html 2> /tmp/wp_plugin_debug_stderr.log; then
    wp plugin install debug-bar --activate --allow-root --path=/var/www/html 2>> /tmp/wp_plugin_debug_stderr.log
    WP_PLUGIN_DEBUG_EXIT_CODE=$?
    echo "DEBUG: debug-bar plugin install finished with exit code: ${WP_PLUGIN_DEBUG_EXIT_CODE}. Stderr:"
    cat /tmp/wp_plugin_debug_stderr.log
fi

# Developer Tools
echo "DEBUG: Installing developer plugin..."
if ! wp plugin is-installed developer --allow-root --path=/var/www/html 2> /tmp/wp_plugin_developer_stderr.log; then
    wp plugin install developer --activate --allow-root --path=/var/www/html 2>> /tmp/wp_plugin_developer_stderr.log || true
    WP_PLUGIN_DEVELOPER_EXIT_CODE=$?
    echo "DEBUG: developer plugin install finished with exit code: ${WP_PLUGIN_DEVELOPER_EXIT_CODE}. Stderr:"
    cat /tmp/wp_plugin_developer_stderr.log
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
echo "📊 Access your site at: http://xandar.127.0.0.1.nip.io"
echo "🔧 Admin credentials: admin/admin"

# Keep the container running
php-fpm

echo "DEBUG: Finished docker-entrypoint-custom.sh"