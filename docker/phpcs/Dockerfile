FROM php:8.3-cli-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    unzip \
    bash \
    make

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set up working directory
WORKDIR /app

# Configure Composer to allow required plugins
RUN composer global config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true

# Install PHP_CodeSniffer and related tools globally
RUN composer global require --no-interaction \
    "squizlabs/php_codesniffer:^3.7" \
    "wp-coding-standards/wpcs:^3.0" \
    "phpcsstandards/phpcsextra:^1.1" \
    "phpcsstandards/phpcsutils:^1.0" \
    "phpcompatibility/php-compatibility:^9.3" \
    "phpcompatibility/phpcompatibility-wp:^2.1" \
    "automattic/vipwpcs:^3.0" \
    "sirbrillig/phpcs-variable-analysis:^2.11" \
    "slevomat/coding-standard:^8.0"

# Add composer global bin to PATH
ENV PATH="/root/.composer/vendor/bin:$PATH"

# Configure PHPCS with all installed standards
RUN phpcs --config-set installed_paths \
    ~/.composer/vendor/wp-coding-standards/wpcs,\
    ~/.composer/vendor/phpcsstandards/phpcsextra,\
    ~/.composer/vendor/phpcsstandards/phpcsutils,\
    ~/.composer/vendor/phpcompatibility/php-compatibility,\
    ~/.composer/vendor/phpcompatibility/phpcompatibility-wp,\
    ~/.composer/vendor/automattic/vipwpcs,\
    ~/.composer/vendor/sirbrillig/phpcs-variable-analysis,\
    ~/.composer/vendor/slevomat/coding-standard

# Set default memory limit for PHPCS
RUN phpcs --config-set memory_limit 512M

# Verify installation
RUN phpcs -i

# Set working directory for code analysis
WORKDIR /data

# Default command
CMD ["phpcs", "--help"]