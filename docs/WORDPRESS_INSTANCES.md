# 🔧 WordPress Instance Management Guide

## Overview

This guide covers how to add, remove, and manage WordPress instances in your development platform. The system is designed to easily scale from 2 to any number of WordPress sites.

## 🆕 Adding New WordPress Instances

### Step 1: Update Environment Configuration

Edit `.env` to add configuration for your new instance:

```bash
# Add new WordPress instance configuration
WORDPRESS_3_VERSION=latest
WORDPRESS_3_DB_NAME=wordpress3

# You can also specify different PHP versions
WORDPRESS_4_VERSION=6.3
WORDPRESS_4_DB_NAME=wordpress4
```

### Step 2: Update Docker Compose

Add the new WordPress service to `docker-compose.yml`:

```yaml
  wordpress3:
    build:
      context: ./docker/wordpress
      dockerfile: Dockerfile
      args:
        - PHP_VERSION=${PHP_VERSION}
        - WORDPRESS_VERSION=${WORDPRESS_3_VERSION}
    container_name: wp_site3
    restart: unless-stopped
    depends_on:
      - db-primary
      - redis
      - memcached
    environment:
      WORDPRESS_DB_HOST: db-primary:3306
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${WORDPRESS_3_DB_NAME}
      WORDPRESS_DEBUG: ${WORDPRESS_DEBUG}
      WORDPRESS_DEBUG_DISPLAY: ${WORDPRESS_DEBUG_DISPLAY}
      WORDPRESS_DEBUG_LOG: ${WORDPRESS_DEBUG_LOG}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_REDIS_HOST', 'redis');
        define('WP_REDIS_PORT', 6379);
        define('WP_CACHE_KEY_SALT', '${WORDPRESS_3_DB_NAME}');
        define('ELASTICSEARCH_HOST', 'elasticsearch:9200');
        define('WP_ENVIRONMENT_TYPE', 'development');
        define('AUTOMATIC_UPDATER_DISABLED', true);
        define('WP_AUTO_UPDATE_CORE', false);
        define('DISALLOW_FILE_EDIT', false);
        define('WP_DEBUG_DISPLAY', ${WORDPRESS_DEBUG_DISPLAY});
        define('WP_DEBUG_LOG', true);
        define('SCRIPT_DEBUG', true);
        define('SAVEQUERIES', true);
        define('WP_MEMORY_LIMIT', '512M');
    volumes:
      - ./wordpress3:/var/www/html
      - ./config/php:/usr/local/etc/php/conf.d:ro
      - ./logs/wordpress3:/var/log/wordpress
      - ./config/nginx/wordpress.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - wp-network
      - monitoring
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 256M
          cpus: '0.25'
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.wordpress3.rule=Host(`wordpress3.${DOMAIN_SUFFIX}`)"
      - "traefik.http.routers.wordpress3.tls=true"
      - "traefik.http.routers.wordpress3.middlewares=security-headers"
      - "traefik.http.services.wordpress3.loadbalancer.server.port=80"
      - "traefik.http.services.wordpress3.loadbalancer.healthcheck.path=/wp-admin/admin-ajax.php"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost/wp-admin/admin-ajax.php?action=heartbeat || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Step 3: Update Database Initialization

Add the new database to `config/mysql/init/01-create-databases.sql`:

```sql
-- Add new database
CREATE DATABASE IF NOT EXISTS wordpress3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress4 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Step 4: Update WP-CLI Configuration

Update the WP-CLI container volumes in `docker-compose.yml`:

```yaml
  wpcli:
    # ... existing configuration ...
    volumes:
      - ./wordpress1:/var/www/html/wordpress1
      - ./wordpress2:/var/www/html/wordpress2
      - ./wordpress3:/var/www/html/wordpress3  # Add new volume
      - ./wordpress4:/var/www/html/wordpress4  # Add new volume
      - ./scripts:/scripts:ro
      - ./backups:/backups
```

### Step 5: Update File Sync Service

Update the file sync environment variables:

```yaml
  file-sync:
    # ... existing configuration ...
    environment:
      SYNC_PATHS: "/app/wordpress1/wp-content/themes,/app/wordpress1/wp-content/plugins,/app/wordpress2/wp-content/themes,/app/wordpress2/wp-content/plugins,/app/wordpress3/wp-content/themes,/app/wordpress3/wp-content/plugins"
      RELOAD_CONTAINERS: "wp_site1,wp_site2,wp_site3"
```

### Step 6: Update Backup Service

Update backup scripts to include new instances. Edit `docker/backup/scripts/backup-all.sh`:

```bash
# Backup WordPress files
log "📁 Backing up WordPress files..."
for site in wordpress1 wordpress2 wordpress3 wordpress4; do
    if [ -d "/var/www/html/$site" ]; then
        log "  📦 Backing up site: $site"
        tar -czf "$BACKUP_BASE/files/${site}_${TIMESTAMP}.tar.gz" \
            -C "/var/www/html" \
            --exclude="$site/wp-content/cache" \
            --exclude="$site/wp-content/uploads/cache" \
            --exclude="$site/*.log" \
            "$site" || error_exit "Failed to backup files for $site"
        log "  ✅ Site $site files backed up"
    else
        log "  ⚠️  Site directory /var/www/html/$site not found, skipping"
    fi
done
```

### Step 7: Create Directory Structure

```bash
# Create directories for new instances
mkdir -p wordpress3 wordpress4 logs/wordpress3 logs/wordpress4

# Set proper permissions
chmod 755 wordpress3 wordpress4
```

### Step 8: Deploy the Changes

```bash
# Rebuild and restart
./wp-dev stop
./wp-dev start

# Or use Docker Compose directly
docker-compose down
docker-compose up -d --build
```

### Step 9: Access Your New Sites

Your new WordPress instances will be available at:
- https://wordpress3.127.0.0.1.nip.io
- https://wordpress4.127.0.0.1.nip.io

## 🗑️ Removing WordPress Instances

### Step 1: Backup Data (Optional)

```bash
# Backup before removal
./wp-dev backup wordpress3
```

### Step 2: Stop and Remove Container

```bash
# Stop the specific container
docker-compose stop wordpress3
docker-compose rm wordpress3
```

### Step 3: Update Docker Compose

Remove the WordPress service definition from `docker-compose.yml`.

### Step 4: Update Environment Configuration

Remove or comment out the configuration in `.env`:

```bash
# WORDPRESS_3_VERSION=latest
# WORDPRESS_3_DB_NAME=wordpress3
```

### Step 5: Clean Up Database (Optional)

```bash
# Connect to database
./wp-dev shell db-primary

# Drop the database (WARNING: This deletes all data!)
mysql -u root -p
DROP DATABASE wordpress3;
```

### Step 6: Clean Up Files

```bash
# Remove WordPress files (WARNING: This deletes all data!)
rm -rf wordpress3
rm -rf logs/wordpress3

# Or move to backup location
mv wordpress3 backups/removed_wordpress3_$(date +%Y%m%d)
```

### Step 7: Update Related Services

Update WP-CLI volumes, file sync paths, and backup scripts to remove references to the deleted instance.

## 🔄 Automated Instance Management

### Using the Instance Manager Script

Create a helper script for easier instance management:

```bash
#!/bin/bash
# WordPress Instance Manager

create_instance() {
    local instance_name=$1
    local wp_version=${2:-latest}
    
    echo "Creating WordPress instance: $instance_name"
    
    # Create directory
    mkdir -p "$instance_name" "logs/$instance_name"
    
    # Add to .env
    echo "WORDPRESS_${instance_name^^}_VERSION=$wp_version" >> .env
    echo "WORDPRESS_${instance_name^^}_DB_NAME=$instance_name" >> .env
    
    # Add database creation
    echo "CREATE DATABASE IF NOT EXISTS $instance_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >> config/mysql/init/01-create-databases.sql
    
    echo "✅ Instance $instance_name created. Please update docker-compose.yml manually."
}

remove_instance() {
    local instance_name=$1
    
    echo "⚠️  This will remove all data for $instance_name"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup first
        ./wp-dev backup "$instance_name" || true
        
        # Stop container
        docker-compose stop "$instance_name" || true
        docker-compose rm -f "$instance_name" || true
        
        # Move files to backup
        if [ -d "$instance_name" ]; then
            mv "$instance_name" "backups/removed_${instance_name}_$(date +%Y%m%d)"
        fi
        
        echo "✅ Instance $instance_name removed"
    fi
}

case "$1" in
    create)
        create_instance "$2" "$3"
        ;;
    remove)
        remove_instance "$2"
        ;;
    *)
        echo "Usage: $0 {create|remove} <instance_name> [wp_version]"
        exit 1
        ;;
esac
```

Save this as `scripts/manage-instances.sh` and make it executable:

```bash
chmod +x scripts/manage-instances.sh

# Usage examples
./scripts/manage-instances.sh create wordpress5 6.3
./scripts/manage-instances.sh remove wordpress3
```

## 🔧 Advanced Instance Configuration

### Different PHP Versions

You can run different PHP versions for different instances:

```yaml
  wordpress-php74:
    build:
      context: ./docker/wordpress
      dockerfile: Dockerfile
      args:
        - PHP_VERSION=7.4  # Different PHP version
        - WORDPRESS_VERSION=6.0  # Compatible WP version
```

### Custom Configurations

Create instance-specific configurations:

```bash
# Create custom PHP config for specific instance
mkdir -p config/php/wordpress3
cp config/php/php.ini config/php/wordpress3/php.ini

# Modify the docker-compose.yml volume mount
volumes:
  - ./config/php/wordpress3:/usr/local/etc/php/conf.d:ro
```

### Separate Databases

You can use separate database containers for isolation:

```yaml
  db-wordpress3:
    image: mysql:8.0
    container_name: wp_db_wordpress3
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: wordpress3
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - db_wordpress3_data:/var/lib/mysql
```

## 📊 Monitoring Multiple Instances

### Grafana Dashboard Updates

Update Prometheus configuration to monitor new instances:

```yaml
# config/prometheus/prometheus.yml
scrape_configs:
  - job_name: 'wordpress'
    static_configs:
      - targets: 
          - 'wordpress1:9090'
          - 'wordpress2:9090'
          - 'wordpress3:9090'  # Add new instances
          - 'wordpress4:9090'
```

### Log Aggregation

All instances automatically send logs to the centralized logging system. Access logs for specific instances:

```bash
# View logs for specific instance
./wp-dev logs wordpress3

# View all WordPress logs
./wp-dev logs | grep wordpress
```

## 🔒 Security Considerations

### Instance Isolation

Each WordPress instance runs in its own container with:
- Separate file systems
- Individual resource limits
- Isolated network access
- Separate log files

### Database Security

- Each instance can have its own database
- Separate database users possible
- Backup isolation
- Access control per instance

## 🚀 Performance Optimization

### Resource Allocation

Adjust resources per instance based on usage:

```yaml
deploy:
  resources:
    limits:
      memory: 2G      # High-traffic site
      cpus: '2.0'
    reservations:
      memory: 512M
      cpus: '0.5'
```

### Cache Separation

Use different Redis databases for cache isolation:

```php
// In wp-config.php for different instances
define('WP_REDIS_DATABASE', 1); // wordpress1 uses DB 1
define('WP_REDIS_DATABASE', 2); // wordpress2 uses DB 2
define('WP_REDIS_DATABASE', 3); // wordpress3 uses DB 3
```

## 📋 Instance Management Checklist

When adding a new instance:

- [ ] Update `.env` with new instance variables
- [ ] Add service definition to `docker-compose.yml`
- [ ] Update database initialization script
- [ ] Update WP-CLI volumes
- [ ] Update file sync configuration
- [ ] Update backup scripts
- [ ] Create directory structure
- [ ] Update monitoring configuration
- [ ] Test the new instance
- [ ] Update documentation

When removing an instance:

- [ ] Create backup of data
- [ ] Stop and remove container
- [ ] Update `docker-compose.yml`
- [ ] Clean up environment variables
- [ ] Remove or backup files
- [ ] Update related services
- [ ] Clean up database (optional)
- [ ] Update monitoring configuration
- [ ] Test remaining instances

This flexible architecture allows you to easily scale your WordPress development environment to meet your specific needs!