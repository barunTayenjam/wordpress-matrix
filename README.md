# 🚀 WordPress Development Platform

A streamlined WordPress development environment with Docker support, comprehensive code quality tools, and simplified management.

## ✨ Key Features

- **⚡ Simplified Management**: All-in-one `matrix` script for easy site management
- **🧪 Code Quality Tools**: PHPStan, PHP CodeSniffer for WordPress development
- **🌐 Multi-Site Environment**: Create and manage multiple WordPress instances
- **🔒 SSL/TLS Support**: Automatic HTTPS with Traefik reverse proxy
- **📊 Development Tools**: Database management, email testing
- **🐳 Docker Support**: Full Docker and docker-compose support

## 🚀 Quick Start

```bash
# Clone and setup
git clone https://github.com/barunTayenjam/wordpress-matrix.git
cd wordpress-matrix

# Quick setup
cp .env.simple .env
cp docker-compose.simple.yml docker-compose.yml
chmod +x matrix
./matrix setup

# Create your first site
./matrix create mysite
./matrix start

# Access your site
# Local: http://localhost:8001
# Domain: https://mysite.127.0.0.1.nip.io
```

## 📖 Documentation

- **[Simplified Platform Guide](README_SIMPLIFIED.md)** - Complete platform documentation
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Essential commands and URLs
- **[Usage Guide](docs/USAGE_GUIDE.md)** - Detailed usage instructions
- **[Code Quality Guide](docs/CODE_QUALITY.md)** - PHPStan, PHPCS, and testing
- **[Debugging Guide](docs/DEBUGGING.md)** - Troubleshooting and debugging

## 🎯 Common Tasks

### Site Management
```bash
# Site management
./matrix create blog          # Create new site
./matrix list                 # List all sites
./matrix start                # Start all sites
./matrix stop                 # Stop all sites
./matrix remove blog          # Remove site

# Development
./matrix shell wp             # Access WordPress CLI
./matrix check                # Run code quality checks
./matrix logs blog            # View site logs
./matrix url blog             # Show site URLs
```

### WordPress CLI Operations
```bash
# Access WordPress CLI
./matrix shell wp
# or
./wp-podman shell wp

# Install plugins/themes
wp plugin install query-monitor --activate --path=/var/www/html/mysite

# Database operations
wp db export backup.sql --path=/var/www/html/mysite
wp db import backup.sql --path=/var/www/html/mysite

# Cache management
wp cache flush --path=/var/www/html/mysite
```

## 🔧 Features

### Code Quality
- **PHPStan**: Static analysis with WordPress globals
- **PHP CodeSniffer**: WordPress coding standards enforcement
- **Quality Reports**: Comprehensive code quality reporting

### Development Tools
- **WordPress CLI**: Pre-configured WP-CLI access
- **Database Management**: phpMyAdmin integration
- **Email Testing**: MailHog for development email testing
- **SSL/TLS**: Automatic HTTPS with Traefik
- **Reverse Proxy**: Traefik with domain-based routing

### Container Services
- **MySQL 8.0**: Primary database with health checks
- **Redis**: In-memory caching and session storage
- **Nginx**: High-performance web server
- **PHP-FPM**: PHP 8.3 with WordPress optimizations
- **Traefik**: Modern reverse proxy and load balancer

## 🌐 Access URLs

### WordPress Sites
| Site Type | URL Pattern | Example |
|-----------|-------------|---------|
| WordPress Sites | `https://<sitename>.127.0.0.1.nip.io` | `https://blog.127.0.0.1.nip.io` |
| Local Access | `http://localhost:<port>` | `http://localhost:8001` |

### Management Tools
| Service | URL | Purpose |
|---------|-----|---------|
| phpMyAdmin | https://phpmyadmin.127.0.0.1.nip.io | Database management |
| MailHog | https://mailhog.127.0.0.1.nip.io | Email testing |
| Traefik Dashboard | http://localhost:8080 | Reverse proxy management |

### Getting Site URLs
```bash
# Show all site URLs
./matrix url

# Show specific site URL
./matrix url mysite

# List sites with URLs
./matrix list
```

## 🛠️ Troubleshooting

### Quick Fixes
```bash
# Services won't start
./matrix clean
./matrix start

# Database issues
./matrix restart db

# Permission problems
sudo chown -R $USER:$USER wp_*

# Clear all caches
./matrix shell wp
wp cache flush --all-sites
```

### Getting Help
1. **Check Status**: `./matrix status`
2. **View Logs**: `./matrix logs`
3. **Review Documentation**: Browse `/docs` folder and `README_SIMPLIFIED.md`
4. **Community Support**: GitHub issues and discussions

### Common Issues
- **Port Conflicts**: Use `./matrix create` to auto-assign ports
- **Permission Errors**: Ensure proper ownership of WordPress directories
- **Database Connection**: Check if database container is running

## 🧪 Code Quality

### Code Quality Checks
```bash
./matrix check                # Quick checks
./matrix quality              # Comprehensive checks
```

### Individual Tools
```bash
./matrix lint                 # PHP CodeSniffer
./matrix analyse              # PHPStan analysis
```

## 🚀 Getting Started Checklist

### First-Time Setup
- [ ] Clone repository: `git clone https://github.com/barunTayenjam/wordpress-matrix.git`
- [ ] Copy configurations: `cp .env.simple .env && cp docker-compose.simple.yml docker-compose.yml`
- [ ] Run setup: `./matrix setup`
- [ ] Create first site: `./matrix create mysite`
- [ ] Start environment: `./matrix start`
- [ ] Access site: `https://mysite.127.0.0.1.nip.io`

### Development Workflow
- [ ] Install code quality tools: `./matrix check`
- [ ] Access WordPress CLI: `./matrix shell wp`
- [ ] Monitor logs: `./matrix logs`

## 📞 Support & Community

### Documentation
- **[Simplified Platform Guide](README_SIMPLIFIED.md)** - Complete platform documentation
- **[Code Quality Guide](docs/CODE_QUALITY.md)** - PHPStan, testing, and quality tools

### Getting Help
1. **Status Check**: `./matrix status`
2. **Review Logs**: `./matrix logs`
3. **Browse Documentation**: Check `/docs` folder and README files
4. **GitHub Issues**: Report bugs and request features

### Community
- **GitHub Discussions**: Community Q&A and tips
- **Issues & PRs**: Bug reports and contributions welcome
- **Documentation**: Contributions to docs appreciated

---

## 🎉 Happy Developing with WordPress Platform!

**Quick Start**: `git clone && cp .env.simple .env && cp docker-compose.simple.yml docker-compose.yml && ./matrix setup && ./matrix create mysite && ./matrix start`