# Integrations - WordPress Matrix Development Platform

## Database: MySQL 8.0

**Connection**: Via Docker container `wp_db` on internal `wp-net` network, exposed on host port 3306.

- **Container**: `mysql:8.0` (container name: `wp_db`)
- **Connection string**: `db:3306` (from other containers), `localhost:3306` (from host)
- **Auth**: Credentials from `.env` (`MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`)
- **Database naming convention**: `<site_name>_db` (e.g., `asgard_db`, `su21_db`, `su26_db`)
- **Volume**: `wp_db_data` (Docker named volume, persistent)
- **Healthcheck**: `mysqladmin ping -h localhost` with 20s timeout, 10 retries
- **Management UI**: phpMyAdmin at `http://localhost:8200` (container `wp_phpmyadmin`)

**Integration points in code**:
- `matrix`: Creates databases via `mysql -e "CREATE DATABASE..."`, imports/exports via `mysqldump`
- `scripts/backup.sh`: Uses `mysqldump` for database backup
- `scripts/clone.sh`: Dumps source DB and pipes to new DB
- `scripts/reset.sh`: Drops and recreates databases
- `scripts/search-replace.sh`: Uses WP-CLI `search-replace` for URL migration
- `scripts/common.sh`: Shared `create_database()` helper

## Cache: Redis

**Connection**: Via Docker container `wp_redis` on `wp-net` network. No host port exposed.

- **Container**: `redis:alpine` (container name: `wp_redis`)
- **Max memory**: 256MB with `allkeys-lru` eviction policy
- **CLI access**: `./matrix shell` then `redis-cli`
- **Purpose**: WordPress object cache backend (requires Redis plugin in WP sites)

**Integration points in code**:
- `scripts/cache-clear.sh`: `redis-cli FLUSHALL` to clear all Redis data
- `scripts/health-check.sh`: `redis-cli ping` to verify connectivity

## WordPress PHP-FPM

Each site runs its own WordPress PHP-FPM container.

- **Images**: `wordpress:php{7.4,8.0,8.1,8.2,8.3}-fpm`
- **Environment**: `WORDPRESS_DB_HOST`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_NAME`, `WORDPRESS_DEBUG`
- **Volumes**: `./wp_<name>:/var/www/html` (bind mount for live file editing)
- **Port**: FPM listens on container port 9000 (internal only)

## Nginx Reverse Proxy

Each site has its own Nginx container as reverse proxy.

- **Image**: `nginx:alpine`
- **Config**: `config/nginx/<site>.conf` (mounted read-only)
- **Upstream**: `fastcgi_pass wp_<site>:9000`
- **Ports**: Each site gets a unique host port (8201, 8202, etc.) mapped to container port 80
- **Features**: Static file caching with `expires max`, PHP execution via FastCGI, security rules (deny hidden files)

## WP-CLI

WordPress command-line interface for site management.

- **Container**: `wordpress:cli` (container name: `wp_cli`)
- **Profile**: `tools` (runs on-demand)
- **Volume**: `./wp_:/var/www/html` (access to all site files)
- **Usage**: `wp search-replace`, `wp core update`, `wp cache flush`

**Integration points in code**:
- `scripts/search-replace.sh`: `wp search-replace` for database URL migration
- `scripts/update-core.sh`: `wp core update` and `wp core update-db`
- `scripts/cache-clear.sh`: `wp cache flush` for WordPress object cache

## PHP CodeSniffer (PHPCS)

WordPress coding standards enforcement.

- **Container**: `wpengine/phpcs:latest` (container name: `wp_phpcs`)
- **Profile**: `tools` (on-demand)
- **Standard**: WordPress Coding Standards (`--standard=WordPress`)
- **Memory**: 512M limit
- **Extensions**: PHP only
- **Exclusions**: Default WP themes (`twenty*`), vendor, node_modules, common third-party plugins

**Integration points in code**:
- `matrix` `run_checks()`: Orchestrates PHPCS execution at `matrix:730`

## PHPStan

Static analysis for PHP code.

- **Container**: `ghcr.io/phpstan/phpstan:latest` (container name: `wp_phpstan`)
- **Profile**: `tools` (on-demand)
- **Memory**: 512M limit
- **Level**: 5 (default, configurable)
- **Scope**: Only runs on specific paths (not all sites at once)

**Integration points in code**:
- `matrix` `run_checks()`: Runs PHPStan only when a specific path is provided (`matrix:800`)

## Frontend (Express.js)

Web-based management dashboard.

- **Runtime**: Node.js on host machine (NOT containerized in production use)
- **Port**: 8500
- **Process management**: Background process with PID file (`.frontend.pid`)
- **Logging**: `logs/frontend.log`
- **Health check**: `GET /health` endpoint, also `GET /api/sites`
- **Communication**: Spawns `matrix` script via `child_process.spawn()` to execute all management commands

**API Endpoints**:
- `GET /` - Dashboard UI (Handlebars rendered)
- `GET /api/sites` - List all sites and services (JSON)
- `POST /api/sites/:action` - Site operations (create, start, stop, remove, info, url)
- `POST /api/environment/:action` - Environment operations (start, stop, restart, status, logs, clean, check)
- `POST /api/frontend/:action` - Frontend management (start, stop, restart, status)
- `GET /api/status` - System status
- `GET /api/help` - Help text
- `GET /health` - Health check

## External CDN References

The frontend loads external resources from CDN:
- Bootstrap 5.3.0 CSS/JS from `cdn.jsdelivr.net`
- Bootstrap Icons 1.10.0 from `cdn.jsdelivr.net`

No authentication or API keys are required for any integrations (all local development).
