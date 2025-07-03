FROM wordpress:cli-php8.3

# Install additional tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    mysql-client \
    rsync \
    zip \
    unzip \
    nano \
    vim \
    jq \
    && rm -rf /var/cache/apk/*

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Install additional WP-CLI packages
RUN wp package install wp-cli/doctor-command --allow-root
RUN wp package install wp-cli/profile-command --allow-root
RUN wp package install wp-cli/find-command --allow-root

# Copy custom scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Set working directory
WORKDIR /var/www/html

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'echo "🛠️  WP-CLI Development Container Ready"' >> /entrypoint.sh && \
    echo 'echo "📁 Available sites:"' >> /entrypoint.sh && \
    echo 'echo "   - wordpress1: /var/www/html/wordpress1"' >> /entrypoint.sh && \
    echo 'echo "   - wordpress2: /var/www/html/wordpress2"' >> /entrypoint.sh && \
    echo 'echo "🔧 Available commands:"' >> /entrypoint.sh && \
    echo 'echo "   - wp-backup: Backup WordPress sites"' >> /entrypoint.sh && \
    echo 'echo "   - wp-restore: Restore WordPress sites"' >> /entrypoint.sh && \
    echo 'echo "   - wp-sync: Sync between sites"' >> /entrypoint.sh && \
    echo 'echo "   - wp-optimize: Optimize WordPress"' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]