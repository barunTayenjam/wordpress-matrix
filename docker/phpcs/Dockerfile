FROM php:8.3-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    unzip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP_CodeSniffer globally
RUN composer global require "squizlabs/php_codesniffer=*"

# Add phpcs to PATH
ENV PATH="/root/.composer/vendor/bin:$PATH"

# Install WordPress Coding Standards
RUN composer global config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true && \
    composer global require wp-coding-standards/wpcs

# Configure PHPCS to use the installed WordPress Coding Standards and its dependencies
RUN phpcs --config-set installed_paths ~/.composer/vendor/wp-coding-standards/wpcs,~/.composer/vendor/phpcsstandards/phpcsextra,~/.composer/vendor/phpcsstandards/phpcsutils