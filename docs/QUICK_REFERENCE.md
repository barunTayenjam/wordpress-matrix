# ⚡ Quick Reference Guide

## 🚀 Essential Commands

### Environment Management
```bash
./wp-dev setup          # Initial setup
./wp-dev start           # Start all services
./wp-dev stop            # Stop all services
./wp-dev restart         # Restart all services
./wp-dev status          # Show service status
./wp-dev clean           # Clean up resources
```

### Development
```bash
./wp-dev shell wpcli     # Access WP-CLI container
./wp-dev shell composer  # Access Composer container
./wp-dev shell node      # Access Node.js container
./wp-dev shell wordpress1 # Access WordPress container
./wp-dev logs -f         # Follow all logs
./wp-dev logs wordpress1 # Show specific service logs
```

### WordPress Management
```bash
# Inside WP-CLI container (./wp-dev shell wpcli)
wp core update --path=/var/www/html/wordpress1
wp plugin install query-monitor --activate --path=/var/www/html/wordpress1
wp theme install twentytwentyfour --path=/var/www/html/wordpress1
wp user create dev dev@example.com --role=administrator --path=/var/www/html/wordpress1
wp db export backup.sql --path=/var/www/html/wordpress1
```

### Backup & Restore
```bash
./wp-dev backup          # Backup all sites
./wp-dev backup wordpress1 # Backup specific site
./wp-dev restore wordpress1 list # List backups
./wp-dev restore wordpress1 20231201_120000 # Restore specific backup
```

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| WordPress 1 | https://wordpress1.127.0.0.1.nip.io | admin/admin |
| WordPress 2 | https://wordpress2.127.0.0.1.nip.io | admin/admin |
| PHPMyAdmin | https://phpmyadmin.127.0.0.1.nip.io | wp_dev_user/(see .env) |
| MailHog | https://mailhog.127.0.0.1.nip.io | No auth |
| Grafana | https://grafana.127.0.0.1.nip.io | admin/(see .env.local) |
| Traefik | https://traefik.127.0.0.1.nip.io | admin/admin |
| Prometheus | https://prometheus.127.0.0.1.nip.io | admin/admin |

## 🔧 Configuration Files

| Component | Configuration File |
|-----------|-------------------|
| Traefik | `config/traefik/traefik.yml` |
| MySQL | `config/mysql/primary.cnf` |
| Redis | `config/redis/redis.conf` |
| PHP | `config/php/php.ini` |
| Nginx | `config/nginx/wordpress.conf` |
| Prometheus | `config/prometheus/prometheus.yml` |
| Grafana | `config/grafana/` |

## 📊 Monitoring Quick Access

### Grafana Dashboards
- **WordPress Performance**: Response times, error rates
- **Database Metrics**: Connections, queries, performance
- **Cache Performance**: Hit rates, memory usage
- **System Resources**: CPU, memory, disk usage

### Prometheus Queries
```promql
# WordPress response time
traefik_service_request_duration_seconds{service="wordpress1"}

# Database connections
mysql_global_status_threads_connected

# Redis memory usage
redis_memory_used_bytes

# Container CPU usage
rate(container_cpu_usage_seconds_total[5m]) * 100
```

## 🐛 Debugging

### Enable Debug Mode
```bash
# Edit .env
WORDPRESS_DEBUG=true
WORDPRESS_DEBUG_DISPLAY=true
WORDPRESS_DEBUG_LOG=true

# Restart containers
./wp-dev restart wordpress1 wordpress2
```

### XDebug Setup
1. **IDE Configuration**: Connect to `localhost:9003`
2. **Path Mapping**: Map local files to `/var/www/html`
3. **Set Breakpoints**: In your PHP files
4. **Start Debugging**: Access your WordPress site

### Log Locations
```bash
# WordPress logs
./logs/wordpress1/
./logs/wordpress2/

# Container logs
./wp-dev logs wordpress1
./wp-dev logs db-primary
./wp-dev logs redis

# PHP error logs
./wp-dev shell wordpress1
tail -f /var/log/php/error.log
```

## 🔒 Security

### Change Default Passwords
```bash
# Generate new passwords
openssl rand -base64 32

# Update .env.local with new passwords
# Restart services
./wp-dev restart
```

### SSL Certificates
- **Development**: Automatic self-signed certificates
- **Production**: Set `SSL_STAGING=false` in .env

## ⚡ Performance

### Clear All Caches
```bash
./wp-dev shell wpcli
wp cache flush --path=/var/www/html/wordpress1
wp redis flush --path=/var/www/html/wordpress1

# Clear OPcache
./wp-dev shell wordpress1
php -r "opcache_reset();"
```

### Database Optimization
```bash
./wp-dev shell wpcli
wp db optimize --path=/var/www/html/wordpress1
wp db repair --path=/var/www/html/wordpress1
```

## 🔄 Instance Management

### Add New WordPress Instance
1. Update `.env` with new instance config
2. Add service to `docker-compose.yml`
3. Update database init script
4. Create directories: `mkdir -p wordpress3 logs/wordpress3`
5. Restart: `./wp-dev restart`

### Remove WordPress Instance
1. Backup: `./wp-dev backup wordpress3`
2. Stop: `docker-compose stop wordpress3`
3. Remove from `docker-compose.yml`
4. Clean up files: `rm -rf wordpress3 logs/wordpress3`

## 🛠️ Troubleshooting

### Common Issues

**Services won't start:**
```bash
docker system prune -f
./wp-dev start
```

**Database connection issues:**
```bash
./wp-dev shell db-primary
mysqladmin ping
```

**Permission issues:**
```bash
sudo chown -R $USER:$USER wordpress1 wordpress2
chmod -R 755 wordpress1 wordpress2
```

**Out of disk space:**
```bash
docker system df
docker system prune -a
./wp-dev clean
```

### Resource Usage
```bash
# Check container resources
docker stats

# Check disk usage
df -h
docker system df

# Check memory usage
free -h
```

## 📦 Package Management

### Composer (PHP Dependencies)
```bash
./wp-dev shell composer
cd /app/wordpress1/wp-content/themes/your-theme
composer install
composer require vendor/package
```

### NPM (JavaScript Dependencies)
```bash
./wp-dev shell node
cd /app/wordpress1/wp-content/themes/your-theme
npm install
npm run build
npm run watch
```

## 🔄 Updates

### Update Platform
```bash
git pull origin main
./wp-dev update
./wp-dev restart
```

### Update WordPress
```bash
./wp-dev shell wpcli
wp core update --path=/var/www/html/wordpress1
wp core update-db --path=/var/www/html/wordpress1
```

### Update Plugins/Themes
```bash
./wp-dev shell wpcli
wp plugin update --all --path=/var/www/html/wordpress1
wp theme update --all --path=/var/www/html/wordpress1
```

## 📞 Support

### Get Help
```bash
./wp-dev help           # Show help
./wp-dev status         # Check system status
./wp-dev logs           # Check logs for errors
```

### Documentation
- [Complete Usage Guide](USAGE_GUIDE.md)
- [WordPress Instance Management](WORDPRESS_INSTANCES.md)
- [Architecture Overview](ARCHITECTURE.md)

### Emergency Recovery
```bash
# Reset everything (WARNING: Deletes all data)
docker-compose down -v
./wp-dev setup
./wp-dev start

# Restore from backup
./wp-dev restore wordpress1 list
./wp-dev restore wordpress1 <backup_timestamp>
```