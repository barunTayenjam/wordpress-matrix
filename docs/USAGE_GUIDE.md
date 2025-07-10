# 📖 Complete Usage Guide

## 🚀 Getting Started

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wp-dev-platform
   ```

2. **Run the setup script**
   ```bash
   ./wp-dev setup
   ```
   This will:
   - Create necessary directories
   - Generate secure passwords
   - Pull Docker images
   - Build custom containers

3. **Start the environment**
   ```bash
   ./wp-dev start
   ```

4. **Access your sites**
   - WordPress 1: https://xandar.127.0.0.1.nip.io
   - WordPress 2: https://sakaar.127.0.0.1.nip.io

## 🎯 Daily Development Workflow

### 1. Starting Your Day
```bash
# Check status
./wp-dev status

# Start if not running
./wp-dev start

# Follow logs
./wp-dev logs -f
```

### 2. WordPress Development
```bash
# Access WP-CLI for site management
./wp-dev shell wpcli

# Inside WP-CLI container:
wp plugin install query-monitor --activate --path=/var/www/html/xandar
wp theme install twentytwentyfour --activate --path=/var/www/html/xandar
wp user create developer dev@example.com --role=administrator --path=/var/www/html/xandar
```

### 3. Database Management
```bash
# Access PHPMyAdmin
# Visit: https://phpmyadmin.127.0.0.1.nip.io
# Credentials: wp_dev_user / (password from .env)

# Or use command line
./wp-dev shell wpcli
wp db export backup.sql --path=/var/www/html/xandar
wp db import backup.sql --path=/var/www/html/sakaar
```

### 4. File Development
```bash
# Edit theme files - hot reload will automatically refresh browser
vim xandar/wp-content/themes/your-theme/style.css

# Install dependencies
./wp-dev shell composer
composer install --working-dir=/app/xandar/wp-content/themes/your-theme

# Node.js development
./wp-dev shell node
cd /app/xandar/wp-content/themes/your-theme
npm install
npm run build
```

### 5. Debugging
```bash
# Enable XDebug (already configured)
# Set breakpoints in your IDE
# Configure IDE to connect to localhost:9003

# View debug logs
./wp-dev logs -f xandar

# Access error logs
./wp-dev shell xandar
tail -f /var/log/php/error.log
```

## 🔧 Advanced Usage

### Code Quality Checks
```bash
# Run PHPStan analysis
./wp-dev shell phpstan
phpstan analyse /app/xandar/wp-content/themes/your-theme

# Run PHPCS code style check
./wp-dev shell phpcs
phpcs --standard=WordPress /data/xandar/wp-content/themes/your-theme

# Fix code style issues
phpcbf --standard=WordPress /data/xandar/wp-content/themes/your-theme
```

### Performance Testing
```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 https://xandar.127.0.0.1.nip.io/

# WordPress performance analysis
./wp-dev shell wpcli
wp profile stage --all --path=/var/www/html/xandar
```

### Backup and Restore
```bash
# Create backup
./wp-dev backup xandar

# List available backups
./wp-dev restore xandar list

# Restore from backup
./wp-dev restore xandar 20231201_120000

# Automated backups run daily at 2 AM
# Check backup logs
./wp-dev logs backup
```

## 📊 Monitoring and Analytics

### Grafana Dashboards
1. **Access Grafana**: https://grafana.127.0.0.1.nip.io
2. **Login**: admin / (password from .env.local)
3. **Available Dashboards**:
   - WordPress Performance Overview
   - Database Metrics
   - Cache Performance
   - System Resources
   - Error Tracking

### Prometheus Metrics
- **Access**: https://prometheus.127.0.0.1.nip.io
- **Query Examples**:
  ```promql
  # WordPress response time
  traefik_service_request_duration_seconds{service="xandar"}
  
  # Database connections
  mysql_global_status_threads_connected
  
  # Redis memory usage
  redis_memory_used_bytes
  ```

### Log Analysis
```bash
# Follow all logs
./wp-dev logs -f

# Specific service logs
./wp-dev logs -f xandar
./wp-dev logs -f db-primary
./wp-dev logs -f redis

# Search logs
./wp-dev logs xandar | grep "ERROR"
```

## 🔒 Security Management

### SSL Certificates
- Automatic HTTPS via Traefik
- Let's Encrypt integration
- Staging mode for development (set SSL_STAGING=false for production)

### Access Control
```bash
# Change Traefik dashboard password
htpasswd -nb admin newpassword | sed -e s/\\$/\\$\\$/g
# Update TRAEFIK_AUTH in .env.local
```

### Security Headers
All security headers are automatically applied:
- HSTS
- Content Security Policy
- X-Frame-Options
- X-XSS-Protection

## 🛠️ Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker resources
docker system df
docker system prune -f

# Check logs for errors
./wp-dev logs

# Restart specific service
./wp-dev restart xandar
```

**Database connection issues:**
```bash
# Check database status
./wp-dev shell db-primary
mysqladmin ping

# Reset database
docker-compose down -v
./wp-dev start
```

**Performance issues:**
```bash
# Check resource usage
docker stats

# Clear all caches
./wp-dev shell wpcli
wp cache flush --path=/var/www/html/xandar
wp redis flush --path=/var/www/html/xandar
```

**SSL certificate issues:**
```bash
# Check Traefik logs
./wp-dev logs traefik

# Force certificate renewal
docker-compose restart traefik
```

### Debug Mode
Enable comprehensive debugging:
```bash
# Edit .env
WORDPRESS_DEBUG=true
WORDPRESS_DEBUG_DISPLAY=true
WORDPRESS_DEBUG_LOG=true
XDEBUG_MODE=debug,develop,coverage

# Restart WordPress containers
./wp-dev restart xandar sakaar
```

## 📈 Performance Optimization

### Cache Management
```bash
# Clear all caches
./wp-dev shell wpcli
wp cache flush --path=/var/www/html/xandar

# Redis cache status
wp redis status --path=/var/www/html/xandar

# OPcache status
./wp-dev shell xandar
php -r "print_r(opcache_get_status());"
```

### Database Optimization
```bash
# Optimize database
./wp-dev shell wpcli
wp db optimize --path=/var/www/html/xandar

# Check database size
wp db size --path=/var/www/html/xandar

# Analyze slow queries
./wp-dev shell db-primary
mysql -e "SELECT * FROM information_schema.processlist WHERE time > 1;"
```

## 🔄 Environment Management

### Development vs Production
```bash
# Development mode (default)
SSL_STAGING=true
WORDPRESS_DEBUG=true

# Production mode
SSL_STAGING=false
WORDPRESS_DEBUG=false
ENABLE_HOT_RELOAD=false
```

### Resource Scaling
```bash
# Adjust in .env
WP_MEMORY_LIMIT=1g
DB_MEMORY_LIMIT=4g
CACHE_MEMORY_LIMIT=1g

# Apply changes
./wp-dev restart
```

## 📚 Additional Resources

### Documentation
- [Architecture Overview](ARCHITECTURE.md)
- [WordPress Instance Management](WORDPRESS_INSTANCES.md)
- [Security Guide](SECURITY.md)
- [Performance Tuning](PERFORMANCE.md)

### Useful Commands Reference
```bash
# Environment management
./wp-dev setup          # Initial setup
./wp-dev start           # Start all services
./wp-dev stop            # Stop all services
./wp-dev restart         # Restart services
./wp-dev status          # Show status
./wp-dev clean           # Clean up resources

# Development
./wp-dev shell wpcli     # Access WP-CLI
./wp-dev shell composer  # Access Composer
./wp-dev shell node      # Access Node.js
./wp-dev logs -f         # Follow logs

# Backup/Restore
./wp-dev backup          # Create backup
./wp-dev restore         # Restore from backup

# Monitoring
./wp-dev monitor         # Open Grafana
```

### Support
- Check logs: `./wp-dev logs`
- Review documentation in `/docs` folder
- Open GitHub issues for bugs
- Community support via discussions