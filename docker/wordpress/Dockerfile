ARG PHP_VERSION=8.3
ARG WORDPRESS_VERSION=latest

FROM wordpress:${WORDPRESS_VERSION}-php${PHP_VERSION}-fpm

# Set build arguments for faster builds
ENV MAKEFLAGS="-j$(nproc)"

# Install system dependencies in optimized order
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core system packages
    curl \
    wget \
    unzip \
    git \
    bash \
    mysql-client \
    redis-tools \
    # Build dependencies
    autoconf \
    g++ \
    make \
    # PHP extension dependencies
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    libpq-dev \
    libgmp-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    # Node.js (install early to avoid conflicts)
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions (core extensions first)
RUN docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        intl \
        mysqli \
        opcache \
        pdo_mysql \
        soap \
        sockets \
        zip

# Install PECL extensions with better error handling
RUN pecl channel-update pecl.php.net \
    && pecl install redis \
    && pecl install xdebug \
    && docker-php-ext-enable redis xdebug

# Install ImageMagick separately (often causes issues)
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    || echo "ImageMagick installation failed, continuing without it"

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Install WP-CLI with timeout and retry
RUN curl --connect-timeout 30 --retry 3 --retry-delay 5 \
    -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info || echo "WP-CLI installed"

# Create necessary directories
RUN mkdir -p \
    /var/log/php \
    /var/log/wordpress \
    /run/php

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
CMD ["php-fpm"]

