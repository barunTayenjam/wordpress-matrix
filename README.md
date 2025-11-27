# 🚀 WordPress Development Platform v1.0

A sophisticated WordPress development environment supporting both **Docker** and **Podman** runtimes with automatic detection, comprehensive code quality tools, and simplified management.

## ✨ Key Features

- **🔄 Dual Runtime Support**: Works with Docker and Podman (auto-detects available runtime)
- **⚡ Simplified Management**: All-in-one `wp-simple` script for easy site management
- **🧪 Code Quality Tools**: PHPStan Level 9, PHP CodeSniffer, Psalm, PHPMD
- **🌐 Multi-Site Environment**: Create and manage multiple WordPress instances
- **🔒 SSL/TLS Support**: Automatic HTTPS with Traefik reverse proxy
- **📊 Development Tools**: Database management, email testing, monitoring
- **🧪 Automated Testing**: Comprehensive test suite with integration tests

## 🚀 Quick Start

### Option 1: Simplified Platform (Recommended)
```bash
# Clone and setup
git clone https://github.com/barunTayenjam/wordpress-matrix.git
cd wordpress-matrix
git checkout v1.0

# Quick setup
cp .env.simple .env
chmod +x wp-simple
./wp-simple setup

# Create your first site
./wp-simple create mysite
./wp-simple start

# Access your site
# Local: http://localhost:8001
# Domain: https://mysite.127.0.0.1.nip.io
```

### Option 2: Advanced Platform
```bash
# Clone and setup
git clone https://github.com/barunTayenjam/wordpress-matrix.git
cd wordpress-matrix
git checkout v1.0

# Setup with Podman/Docker detection
chmod +x wp-podman
./wp-podman setup

# Create and start sites
./wp-podman create mysite
./wp-podman start
```

### Option 3: Legacy Platform
```bash
# Clone and setup
git clone https://github.com/barunTayenjam/wordpress-matrix.git
cd wordpress-matrix
git checkout v1.0

# Traditional setup
./wp-dev setup
./wp-dev start
```

## 📖 Documentation

### v1.0 Platform Guides
- **[Simplified Platform Guide](README_SIMPLIFIED.md)** - Complete simplified platform documentation
- **[Quick Reference](QUICK_REFERENCE.md)** - Essential commands and URLs
- **[Usage Guide](USAGE_GUIDE.md)** - Detailed usage instructions
- **[Architecture Overview](ARCHITECTURE.md)** - System design and components

### Management Scripts
- **[AGENTS.md](AGENTS.md)** - Complete guide for agents and developers
- **[WordPress Instance Management](WORDPRESS_INSTANCES.md)** - Add/remove WordPress sites
- **[Code Quality Guide](CODE_QUALITY.md)** - PHPStan, PHPCS, and testing
- **[Platform Compatibility](PLATFORM_COMPATIBILITY.md)** - Docker/Podman compatibility
- **[Debugging Guide](DEBUGGING.md)** - Troubleshooting and debugging

### Advanced Topics
- **[Port Access Guide](PORT_ACCESS_GUIDE.md)** - Port management and access
- **[Site Management](SITE_MANAGEMENT.md)** - Advanced site management

## 🎯 Common Tasks

### Simplified Platform (wp-simple)
```bash
# Site management
./wp-simple create blog          # Create new site
./wp-simple list                 # List all sites
./wp-simple start                # Start all sites
./wp-simple stop                 # Stop all sites
./wp-simple remove blog          # Remove site

# Development
./wp-simple shell wp             # Access WordPress CLI
./wp-simple check                # Run code quality checks
./wp-simple logs blog            # View site logs
./wp-simple url blog             # Show site URLs
```

### Podman-First Platform (wp-podman)
```bash
# Runtime detection
./wp-podman runtime              # Show which runtime is used

# Site management
./wp-podman create blog          # Create new site
./wp-podman start               # Start environment
./wp-podman list                # List sites

# Code quality
./wp-podman lint                # PHP CodeSniffer
./wp-podman analyse             # PHPStan analysis
./wp-podman quality             # All quality checks
```

### WordPress CLI Operations
```bash
# Access WordPress CLI
./wp-simple shell wp
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

## 🔧 Advanced Features

### Code Quality & Testing
- **PHPStan Level 9**: Strict static analysis with WordPress globals
- **PHP CodeSniffer**: WordPress coding standards enforcement
- **Psalm**: Type checking and static analysis
- **PHP Mess Detector**: Code quality analysis
- **Automated Testing**: Integration tests and test runners
- **Quality Reports**: Comprehensive code quality reporting

### Runtime Support
- **Docker**: Full Docker and docker-compose support
- **Podman**: Native Podman and podman-compose support
- **Auto-Detection**: Automatically detects and uses available runtime
- **Runtime Switching**: Seamless switching between Docker and Podman

### Development Tools
- **WordPress CLI**: Pre-configured WP-CLI access
- **Database Management**: phpMyAdmin integration
- **Email Testing**: MailHog for development email testing
- **SSL/TLS**: Automatic HTTPS with Traefik
- **Reverse Proxy**: Traefik with domain-based routing
- **Hot Reload**: File change detection and auto-refresh

### Container Services
- **MySQL 8.0**: Primary database with health checks
- **Redis**: In-memory caching and session storage
- **Nginx**: High-performance web server
- **PHP-FPM**: PHP 8.3 with WordPress optimizations
- **Traefik**: Modern reverse proxy and load balancer

## 🌐 Access URLs

### Dynamic Sites (Simplified Platform)
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

### Legacy Sites (Advanced Platform)
| Service | URL | Purpose |
|---------|-----|---------|
| WordPress 1 | https://xandar.127.0.0.1.nip.io | Primary development site |
| WordPress 2 | https://sakaar.127.0.0.1.nip.io | Secondary development site |

### Getting Site URLs
```bash
# Show all site URLs
./wp-simple url

# Show specific site URL
./wp-simple url mysite

# List sites with URLs
./wp-simple list
```

## 🛠️ Troubleshooting

### Quick Fixes
```bash
# Services won't start (Simplified)
./wp-simple clean
./wp-simple start

# Services won't start (Podman)
./wp-podman clean
./wp-podman start

# Runtime issues
./wp-podman runtime              # Check which runtime is used

# Database issues
./wp-simple restart db           # Simplified
./wp-podman stop && ./wp-podman start  # Podman

# Permission problems
sudo chown -R $USER:$USER wp_*

# Clear all caches
./wp-simple shell wp
wp cache flush --all-sites
```

### Getting Help
1. **Check Status**: `./wp-simple status` or `./wp-podman status`
2. **View Logs**: `./wp-simple logs` or `./wp-podman logs`
3. **Runtime Info**: `./wp-podman runtime`
4. **Review Documentation**: Browse `/docs` folder and `README_SIMPLIFIED.md`
5. **Community Support**: GitHub issues and discussions

### Common Issues
- **Port Conflicts**: Use `./wp-simple create` to auto-assign ports
- **Runtime Detection**: Install either Docker or Podman (scripts auto-detect)
- **Permission Errors**: Ensure proper ownership of WordPress directories
- **Database Connection**: Check if database container is running

## 🧪 Testing & Quality Assurance

### Running Tests
```bash
# Run all tests
./tests/test-runner.sh all

# Run specific test categories
./tests/test-runner.sh unit
./tests/test-runner.sh integration

# Test Podman compatibility
./test-wp-podman.sh
```

### Code Quality Checks
```bash
# Simplified platform
./wp-simple check                # Quick checks
./wp-simple quality              # Comprehensive checks

# Podman platform
./wp-podman quick-check          # Essential checks
./wp-podman quality              # All quality tools

# Individual tools
./wp-podman lint                 # PHP CodeSniffer
./wp-podman analyse              # PHPStan Level 9
./wp-podman phpmd                # PHP Mess Detector
./wp-podman psalm                # Psalm analysis
```

## 🔄 Runtime Comparison

| Feature | Docker | Podman | Auto-Detection |
|---------|--------|--------|----------------|
| Container Runtime | ✅ | ✅ | ✅ |
| Compose Support | ✅ | ✅ | ✅ |
| Rootless Mode | ❌ | ✅ | ✅ |
| System Integration | ✅ | ✅ | ✅ |
| Performance | High | High | Auto-Optimized |

## 📦 Platform Versions

### v1.0 Features
- ✅ Dual runtime support (Docker + Podman)
- ✅ Simplified management scripts
- ✅ Comprehensive code quality tools
- ✅ Automated testing suite
- ✅ SSL/TLS with Traefik
- ✅ Multi-site WordPress support
- ✅ Database management tools
- ✅ Development shell access

### Choosing the Right Version
- **Simplified (`wp-simple`)**: Quick setup, fewer commands, ideal for most users
- **Podman-First (`wp-podman`)**: Advanced features, runtime flexibility, power users
- **Legacy (`wp-dev`)**: Existing installations, complex enterprise setups

## 🚀 Getting Started Checklist

### First-Time Setup
- [ ] Clone repository: `git clone https://github.com/barunTayenjam/wordpress-matrix.git`
- [ ] Checkout v1.0: `git checkout v1.0`
- [ ] Choose platform: `wp-simple` (recommended) or `wp-podman`
- [ ] Run setup: `./wp-simple setup` or `./wp-podman setup`
- [ ] Create first site: `./wp-simple create mysite`
- [ ] Start environment: `./wp-simple start`
- [ ] Access site: `https://mysite.127.0.0.1.nip.io`

### Development Workflow
- [ ] Install code quality tools: `./wp-simple check`
- [ ] Access WordPress CLI: `./wp-simple shell wp`
- [ ] Monitor logs: `./wp-simple logs`
- [ ] Run tests: `./tests/test-runner.sh all`

## 📞 Support & Community

### Documentation
- **[Simplified Platform Guide](README_SIMPLIFIED.md)** - Complete simplified documentation
- **[AGENTS.md](AGENTS.md)** - Developer and agent guide
- **[Code Quality Guide](CODE_QUALITY.md)** - PHPStan, testing, and quality tools

### Getting Help
1. **Check Runtime**: `./wp-podman runtime` (shows Docker/Podman status)
2. **Status Check**: `./wp-simple status` or `./wp-podman status`
3. **Review Logs**: `./wp-simple logs` or `./wp-podman logs`
4. **Browse Documentation**: Check `/docs` folder and README files
5. **GitHub Issues**: Report bugs and request features

### Community
- **GitHub Discussions**: Community Q&A and tips
- **Issues & PRs**: Bug reports and contributions welcome
- **Documentation**: Contributions to docs appreciated

---

## 🎉 Happy Developing with WordPress Platform v1.0!

This platform provides everything you need for professional WordPress development with both Docker and Podman support. Start with the simplified platform for quick results, or explore advanced features as needed.

**Quick Start**: `git clone && ./wp-simple setup && ./wp-simple create mysite && ./wp-simple start`