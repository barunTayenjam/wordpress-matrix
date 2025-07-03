#!/bin/bash
# WordPress Optimization Script

echo "🔧 Running WordPress optimizations..."

# Flush rewrite rules
wp rewrite flush --allow-root --path=/var/www/html

# Update database
wp core update-db --allow-root --path=/var/www/html

# Optimize database
wp db optimize --allow-root --path=/var/www/html

# Clear all caches
wp cache flush --allow-root --path=/var/www/html

# Enable Redis Object Cache if plugin is active
if wp plugin is-active redis-cache --allow-root --path=/var/www/html; then
    wp redis enable --allow-root --path=/var/www/html || true
fi

# Set proper file permissions for uploads
if [ -d "/var/www/html/wp-content/uploads" ]; then
    chmod -R 755 /var/www/html/wp-content/uploads
    chown -R www-data:www-data /var/www/html/wp-content/uploads
fi

# Create .htaccess with WordPress rules
if [ ! -f "/var/www/html/.htaccess" ]; then
    wp rewrite structure '/%postname%/' --allow-root --path=/var/www/html
fi

# Install must-use plugins directory
mkdir -p /var/www/html/wp-content/mu-plugins
chown -R www-data:www-data /var/www/html/wp-content/mu-plugins

echo "✅ WordPress optimization completed!"