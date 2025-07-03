# 🚀 World-Class WordPress Development Platform

A comprehensive, production-ready WordPress development environment built with Docker, featuring advanced monitoring, caching, security, and developer tools.

## ✨ Features

### 🏗️ **Infrastructure**
- **Traefik v3.0** - Modern reverse proxy with automatic HTTPS
- **MySQL 8.0** - High-performance database with replication
- **Redis 7** - Advanced caching layer
- **Elasticsearch** - Full-text search capabilities
- **Nginx** - Optimized web server

### 🔧 **Development Tools**
- **PHP 8.3** - Latest PHP with all extensions
- **XDebug** - Advanced debugging capabilities
- **WP-CLI** - Command-line WordPress management
- **Composer** - PHP dependency management
- **Node.js 20** - Modern JavaScript tooling
- **Hot Reload** - Automatic browser refresh on file changes

### 📊 **Monitoring & Analytics**
- **Prometheus** - Metrics collection
- **Grafana** - Beautiful dashboards
- **Health Checks** - Automatic service monitoring
- **Log Aggregation** - Centralized logging

### 🔒 **Security**
- **SSL/TLS** - Automatic HTTPS certificates
- **Security Headers** - OWASP recommended headers
- **Rate Limiting** - DDoS protection
- **IP Whitelisting** - Admin area protection

### 🚀 **Performance**
- **OPcache** - PHP bytecode caching
- **Redis Object Cache** - WordPress object caching
- **Memcached** - Additional caching layer
- **Gzip Compression** - Optimized content delivery
- **Resource Limits** - Controlled resource usage

### 🔄 **Backup & Recovery**
- **Automated Backups** - Scheduled database and file backups
- **S3 Integration** - Cloud backup storage
- **Point-in-time Recovery** - Restore to any backup
- **Retention Policies** - Automatic cleanup

### 🧪 **Code Quality**
- **PHPStan** - Static analysis
- **PHPCS** - Code style checking
- **WordPress Coding Standards** - Best practices enforcement

## 🚀 Quick Start

### Prerequisites

#### **Supported Platforms**
- ✅ **Mac Silicon (M1/M2/M3/M4)** - Native ARM64 support
- ✅ **Mac Intel** - Full x86_64 compatibility  
- ✅ **Linux** - Ubuntu, Debian, CentOS, RHEL, Fedora, Arch
- ✅ **Windows WSL2** - Windows 10/11 with WSL2

#### **System Requirements**
- **Docker 20.10+** (Docker Desktop 4.12+ for Mac/Windows)
- **Docker Compose 2.0+**
- **8GB RAM minimum** (16GB recommended)
- **20GB free disk space** (50GB recommended)
- **Multi-core CPU** (4+ cores recommended)

### Installation

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd wp-dev-platform
   ./scripts/dev/setup.sh
   ```

2. **Start Environment**
   ```bash
   ./scripts/dev/start.sh
   ```

3. **Access Your Sites**
   - WordPress 1: https://wordpress1.127.0.0.1.nip.io
   - WordPress 2: https://wordpress2.127.0.0.1.nip.io
   - PHPMyAdmin: https://phpmyadmin.127.0.0.1.nip.io
   - MailHog: https://mailhog.127.0.0.1.nip.io
   - Grafana: https://grafana.127.0.0.1.nip.io
   - Traefik Dashboard: https://traefik.127.0.0.1.nip.io

## 🛠️ Usage

### WordPress Management

```bash
# Access WP-CLI
docker-compose exec wpcli bash

# Install plugins
wp plugin install query-monitor --activate --path=/var/www/html/wordpress1

# Update WordPress
wp core update --path=/var/www/html/wordpress1

# Database operations
wp db export backup.sql --path=/var/www/html/wordpress1
```

### Development Workflow

```bash
# Watch logs
docker-compose logs -f wordpress1

# Restart services
docker-compose restart wordpress1

# Access container shell
docker-compose exec wordpress1 bash

# Run code quality checks
docker-compose exec phpstan analyse /app/wordpress1/wp-content/themes/
docker-compose exec phpcs --standard=WordPress /data/wordpress1/wp-content/themes/
```

### Backup & Restore

```bash
# Manual backup
docker-compose exec wpcli wp-backup wordpress1

# List backups
docker-compose exec wpcli wp-restore wordpress1 list

# Restore from backup
docker-compose exec wpcli wp-restore wordpress1 20231201_120000
```

## 📊 Monitoring

### Grafana Dashboards
Access Grafana at https://grafana.127.0.0.1.nip.io with credentials from `.env.local`

**Available Dashboards:**
- WordPress Performance Overview
- Database Metrics
- Cache Performance
- System Resources
- Error Tracking

### Prometheus Metrics
- WordPress response times
- Database performance
- Cache hit rates
- System resources
- Custom application metrics

### Health Checks
All services include health checks accessible via:
```bash
docker-compose ps
```

## 🔧 Configuration

### Environment Variables
Key configuration options in `.env`:

```bash
# PHP Settings
PHP_VERSION=8.3
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300

# WordPress Versions
WORDPRESS_1_VERSION=6.4
WORDPRESS_2_VERSION=latest

# Performance
REDIS_MAXMEMORY=256mb
ENABLE_HOT_RELOAD=true

# Security
SSL_STAGING=true  # Set to false for production
```

### Custom PHP Configuration
Edit `config/php/php.ini` for custom PHP settings.

### Database Optimization
MySQL configuration in `config/mysql/primary.cnf` and `config/mysql/replica.cnf`.

### Nginx Optimization
Web server configuration in `config/nginx/wordpress.conf`.

## 🔒 Security

### SSL Certificates
- Automatic HTTPS via Traefik
- Let's Encrypt integration
- Staging mode for development

### Access Control
- Basic authentication for admin tools
- IP whitelisting for sensitive areas
- Rate limiting for API endpoints

### Security Headers
- HSTS enforcement
- XSS protection
- Content Security Policy
- Frame options

## 🚀 Performance Optimization

### Caching Strategy
1. **OPcache** - PHP bytecode caching
2. **Redis** - Object and page caching
3. **Memcached** - Additional memory caching
4. **Browser Caching** - Static asset caching

### Database Optimization
- MySQL 8.0 with optimized configuration
- Read replica for scaling
- Query optimization
- Index optimization

### Resource Management
- Container resource limits
- Memory usage monitoring
- CPU usage optimization
- Disk space management

## 🧪 Testing

### Code Quality
```bash
# Static analysis
docker-compose exec phpstan analyse /app/wordpress1/

# Code style
docker-compose exec phpcs --standard=WordPress /data/wordpress1/

# WordPress coding standards
docker-compose exec phpcs --standard=WordPress-Core /data/wordpress1/
```

### Performance Testing
```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 https://wordpress1.127.0.0.1.nip.io/

# Database performance
docker-compose exec wpcli wp db check --path=/var/www/html/wordpress1
```

## 🔄 Backup Strategy

### Automated Backups
- **Schedule**: Daily at 2 AM (configurable)
- **Retention**: 30 days (configurable)
- **Storage**: Local + S3 (optional)
- **Compression**: Gzip for space efficiency

### Manual Backups
```bash
# Full backup
docker-compose exec backup /usr/local/bin/backup-all.sh

# Site-specific backup
docker-compose exec wpcli wp-backup wordpress1
```

### Disaster Recovery
```bash
# List available backups
docker-compose exec wpcli wp-restore wordpress1 list

# Restore from specific backup
docker-compose exec wpcli wp-restore wordpress1 20231201_120000
```

## 🛠️ Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker resources
docker system df
docker system prune

# Check logs
docker-compose logs [service-name]
```

**Database connection issues:**
```bash
# Check database status
docker-compose exec db-primary mysqladmin ping

# Reset database
docker-compose down -v
docker-compose up -d
```

**Performance issues:**
```bash
# Check resource usage
docker stats

# Monitor logs
docker-compose logs -f --tail=100
```

### Debug Mode
Enable debug mode by setting in `.env`:
```bash
WORDPRESS_DEBUG=true
WORDPRESS_DEBUG_DISPLAY=true
WORDPRESS_DEBUG_LOG=true
```

## 📚 Documentation

### Platform Support
- **[Platform Compatibility](docs/PLATFORM_COMPATIBILITY.md)** - Mac Silicon, Intel, Linux, WSL2 support

### Core Guides
- **[Usage Guide](docs/USAGE_GUIDE.md)** - Complete usage instructions
- **[WordPress Instances](docs/WORDPRESS_INSTANCES.md)** - Add/remove WordPress sites
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Essential commands and troubleshooting
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design and components

### Development
- [Plugin Development](docs/plugin-development.md)
- [Theme Development](docs/theme-development.md)
- [Custom Workflows](docs/workflows.md)

### Operations
- [Deployment Guide](docs/deployment.md)
- [Monitoring Setup](docs/monitoring.md)
- [Backup Procedures](docs/backup.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- WordPress Community
- Docker Community
- Traefik Team
- Prometheus & Grafana Teams
- All open-source contributors

---

**Built with ❤️ by Rovo Dev - Senior Architect**

For support, please open an issue or contact the development team.