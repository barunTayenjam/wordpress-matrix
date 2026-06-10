# Docker Compose Services

## Database (db)
- Container: wp_db
- Image: mysql:8.0
- Port: 3306
- Volume: wp_db_data:/var/lib/mysql

## Cache (redis)
- Container: wp_redis
- Image: redis:alpine
- Config: maxmemory 256mb, allkeys-lru eviction

## Database Management (phpmyadmin)
- Container: wp_phpmyadmin
- Image: phpmyadmin/phpmyadmin:5.2.1
- Port: 8200
- Connects to: db

## Email Testing (mailpit)
- Container: wp_mailpit
- Image: axllent/mailpit:latest
- Ports: 1025 (SMTP), 8025 (UI)

## Code Quality Tools
- phpcs: wpengine/phpcs:latest (profile: tools)
- phpstan: ghcr.io/phpstan/phpstan:latest (profile: tools)

## Development Tools
- wp-cli: wordpress:cli (profile: tools)

## WordPress Sites
- wp_su21: wordpress:php7.4-fpm with nginx_su21 on port 8201

## Networks
- wp-net: bridge driver

## Volumes
- wp_db_data: persistent MySQL data
