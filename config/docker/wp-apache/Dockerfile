# Apache + PHP-FPM stack for matrix, rebased on Ubuntu 24.04 (Noble) so that
# curl 8.5.0 / OpenSSL 3.0.13 match production Site Health exactly.
#
# NOTE: PHP 8.3 is the only version natively available on Ubuntu 24.04.
# Other PHP versions (7.4–8.2) are NOT supported on this apache stack without
# adding ondrej/php PPA. Use the nginx stack (official wordpress:*-fpm images)
# for non-8.3 apache needs.
ARG PHP_VERSION=8.3
FROM ubuntu:24.04

ARG PHP_VERSION=8.3

ENV DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=${PHP_VERSION}

COPY apache-wordpress.conf /etc/apache2/sites-available/wordpress.conf
COPY php-prod-parity.ini /etc/php/${PHP_VERSION}/fpm/conf.d/zz-prod-parity.ini
COPY docker-entrypoint-apache-fpm.sh /usr/local/bin/docker-entrypoint-apache-fpm.sh
COPY su26.crt /etc/apache2/ssl/su26.crt
COPY su26.key /etc/apache2/ssl/su26.key

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 \
        ca-certificates \
        curl \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-redis \
        less \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp \
    && wp --allow-root cli info >/dev/null 2>&1 \
    && mkdir -p /etc/apache2/ssl \
    && a2enmod proxy proxy_fcgi headers expires rewrite deflate filter setenvif mime brotli http2 ssl \
    && a2dissite 000-default.conf \
    && a2ensite wordpress.conf \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && echo 'BrotliCompressionQuality 5' > /etc/apache2/conf-available/brotli-custom.conf \
    && a2enconf brotli-custom \
    && sed -i "s|php8.3-fpm.sock|php${PHP_VERSION}-fpm.sock|" /etc/apache2/sites-available/wordpress.conf \
    && mkdir -p /etc/php/${PHP_VERSION}/fpm/pool.d \
    && { printf '\n; matrix overrides\n'; \
         printf 'listen = /run/php/php%s-fpm.sock\n' "$PHP_VERSION"; \
         printf 'listen.owner = www-data\n'; \
         printf 'listen.group = www-data\n'; \
         printf 'listen.mode = 0660\n'; \
         printf 'clear_env = no\n'; \
       } >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
    && chmod +x /usr/local/bin/docker-entrypoint-apache-fpm.sh

EXPOSE 80
ENTRYPOINT ["docker-entrypoint-apache-fpm.sh"]
