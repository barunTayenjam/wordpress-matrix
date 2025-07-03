ARG PHP_VERSION=8.3
ARG WORDPRESS_VERSION=latest

FROM wordpress:${WORDPRESS_VERSION}-php${PHP_VERSION}-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    wget \
    unzip \
    git \
    bash \
    mysql-client \
    redis \
    imagemagick \
    imagemagick-dev \
    autoconf \
    g++ \
    make \
    linux-headers \
    && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN docker-php-ext-install \
    bcmath \
    exif \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    soap \
    sockets \
    zip

# Install PECL extensions
RUN pecl install \
    redis \
    xdebug \
    imagick \
    && docker-php-ext-enable \
    redis \
    xdebug \
    imagick

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install Node.js and npm
RUN apk add --no-cache nodejs npm

# Create necessary directories
RUN mkdir -p \
    /var/log/nginx \
    /var/log/php \
    /var/log/supervisor \
    /var/log/wordpress \
    /run/nginx \
    /run/php

# Copy configuration files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Copy WordPress optimization scripts
COPY wp-optimize.sh /usr/local/bin/wp-optimize
COPY entrypoint.sh /usr/local/bin/docker-entrypoint-custom
RUN chmod +x /usr/local/bin/wp-optimize /usr/local/bin/docker-entrypoint-custom

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]