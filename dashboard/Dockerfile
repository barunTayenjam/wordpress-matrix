FROM php:8.3-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    zip \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Copy the wp-simple script
COPY wp-simple /usr/local/bin/wp-simple
RUN chmod +x /usr/local/bin/wp-simple

WORKDIR /var/www/html

# Copy dashboard files
COPY dashboard/frontend/ /var/www/html/
COPY dashboard/api/ /var/www/api/

# Install PHP extensions commonly needed for this type of application
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Configure PHP
RUN echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/app.ini && \
    echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/app.ini

# Create a directory for API access
RUN ln -sf /usr/local/bin/wp-simple /var/www/html/wp-simple && \
    ln -sf /var/www/api /var/www/html/api

CMD ["php-fpm"]