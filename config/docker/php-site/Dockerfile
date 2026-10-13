# matrix-php — shared runtime for all non-wp site types (laravel, symfony,
# drupal, joomla, grav). Composer + unzip baked in so composer create-project
# platform requirements (intl, zip, pdo_mysql...) resolve in the same image
# that later serves the site. Spec: docs/superpowers/specs/2026-10-13-multi-php-stack-support-design.md
ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libicu-dev \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd intl zip bcmath pdo_mysql

RUN curl -sS https://getcomposer.org/installer \
        | php -- --install-dir=/usr/local/bin --filename=composer
