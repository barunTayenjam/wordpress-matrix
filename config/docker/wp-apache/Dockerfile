ARG PHP_VERSION=8.3
FROM wordpress:php${PHP_VERSION}-fpm
ARG PHP_VERSION

COPY apache-wordpress.conf /etc/apache2/sites-available/wordpress.conf
COPY php-prod-parity.ini /usr/local/etc/php/conf.d/zz-prod-parity.ini
COPY docker-entrypoint-apache-fpm.sh /usr/local/bin/docker-entrypoint-apache-fpm.sh

# Apache + PHP-FPM in one container (matches prod: Apache 2.4 + fpm-fcgi).
RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod proxy proxy_fcgi headers expires rewrite deflate filter setenvif mime brotli \
    && a2dissite 000-default.conf \
    && a2ensite wordpress.conf \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && mkdir -p /run/php \
    && chown www-data:www-data /run/php \
    && echo 'BrotliCompressionQuality 5' > /etc/apache2/conf-available/brotli-custom.conf \
    && a2enconf brotli-custom \
    && sed -i "s|^;listen = 127.0.0.1:9000|listen = /run/php/php${PHP_VERSION}-fpm.sock|" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|^;listen.owner = www-data|listen.owner = www-data|' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|^;listen.group = www-data|listen.group = www-data|' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|^;listen.mode = 0660|listen.mode = 0660|' /usr/local/etc/php-fpm.d/www.conf \
    && chmod +x /usr/local/bin/docker-entrypoint-apache-fpm.sh

EXPOSE 80
ENTRYPOINT ["docker-entrypoint-apache-fpm.sh"]
