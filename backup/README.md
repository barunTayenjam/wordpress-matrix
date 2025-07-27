# 🚀 WordPress Matrix

*A complete WordPress development platform with nip.io-only architecture.*

This repository provides a production-ready, developer-focused WordPress development environment. Built on Docker with clean domain-based access, it includes all essential tools for modern WordPress development without port management complexity.

---

## 🌟 Features

### ✅ **Clean nip.io-Only Architecture**
- No port access needed - all services via clean domains
- SSL/TLS ready with automatic certificates
- Unlimited WordPress sites without port conflicts

### ✅ **Complete Development Ecosystem**
- WordPress development sites with isolated environments
- Database management via phpMyAdmin
- Email testing with MailHog
- Code quality tools integration
- Performance caching (Redis + Memcached)

### ✅ **Dynamic Site Management**
- Create/delete WordPress sites with single commands
- Automatic domain routing and database creation
- Complete site lifecycle management

---

## 🚀 Quick Start

### 1. Prerequisites
- Docker Desktop installed and running
- No port requirements (uses domains only)

### 2. Launch the Platform
```bash
# Start all services
docker-compose -f docker-compose-nip-fixed.yml up -d
```

### 3. Access Your Development Environment
- **WordPress Sites**: 
  - xandar.127.0.0.1.nip.io
  - asgard.127.0.0.1.nip.io
- **Development Tools**:
  - phpmyadmin.127.0.0.1.nip.io (Database management)
  - mailhog.127.0.0.1.nip.io (Email testing)
  - codetools.127.0.0.1.nip.io (Code quality tools)

---

## 🛠️ Site Management

### Creating New Sites

Create a new WordPress site with automatic setup:

```bash
# Interactive creation
./scripts/manage-sites.sh create

# Direct creation
./scripts/manage-sites.sh create myproject
```

Each new site automatically gets:
- Dedicated WordPress container
- Separate MySQL database
- SSL/TLS certificate via Traefik
- Clean domain: `sitename.127.0.0.1.nip.io`

### Managing Existing Sites

```bash
# List all sites and their status
./scripts/manage-sites.sh list

# Get detailed site information
./scripts/manage-sites.sh info sitename

# Start/stop/restart sites
./scripts/manage-sites.sh start sitename
./scripts/manage-sites.sh stop sitename
./scripts/manage-sites.sh restart sitename

# Remove a site completely
./scripts/manage-sites.sh remove sitename
```

---

## 🏗️ Architecture

### Clean nip.io-Only Design
```
Internet → Traefik (SSL/TLS) → WordPress Containers
                ↓
    sitename.127.0.0.1.nip.io → Dedicated WordPress
```

### Infrastructure Services
- **Traefik**: Reverse proxy with automatic SSL
- **MySQL**: Database server with isolated databases
- **Redis**: Object caching for performance
- **Memcached**: Additional caching layer

### Development Tools
- **phpMyAdmin**: `phpmyadmin.127.0.0.1.nip.io`
- **MailHog**: `mailhog.127.0.0.1.nip.io`
- **Code Quality**: `codetools.127.0.0.1.nip.io`

---

## 📁 Project Structure

```
wordpress-matrix/
├── scripts/                 # Site management scripts
├── config/                  # Service configurations
│   ├── nginx/              # Nginx configurations
│   ├── phpcs/              # Code quality configs
│   └── traefik/            # SSL/TLS configs
├── xandar/                 # WordPress site 1
├── asgard/                 # WordPress site 2
├── logs/                   # Application logs
└── backup/                 # Backup files
```

---

## 🎯 Development Workflow

### Daily Development
1. **Access Sites**: Visit `sitename.127.0.0.1.nip.io`
2. **Database Work**: Use `phpmyadmin.127.0.0.1.nip.io`
3. **Email Testing**: Check `mailhog.127.0.0.1.nip.io`
4. **Code Quality**: Run checks via `codetools.127.0.0.1.nip.io`

### Project Management
1. **New Project**: `./scripts/manage-sites.sh create clientproject`
2. **Development**: Work on `clientproject.127.0.0.1.nip.io`
3. **Testing**: Use integrated development tools
4. **Completion**: `./scripts/manage-sites.sh remove clientproject`

### Performance Features
- **Redis Caching**: Automatic object caching
- **SSL/TLS**: Production-ready certificates
- **Isolated Environments**: No cross-site interference
- **Scalable**: Unlimited sites without port conflicts

---

## 🔧 Configuration

### Environment Variables

Key environment variables in `.env`:
- `DOMAIN_SUFFIX`: Domain suffix for sites (default: 127.0.0.1.nip.io)
- `MYSQL_ROOT_PASSWORD`: MySQL root password
- `WORDPRESS_DEBUG`: Enable WordPress debugging

### Default Credentials
- **MySQL Root**: `SecureRoot2024!`
- **phpMyAdmin**: `root` / `SecureRoot2024!`

---

## 🚀 Advanced Features

### Performance Optimization
- Redis object caching
- Memcached support
- Optimized PHP configuration
- SSL/TLS termination

### Development Tools
- **phpMyAdmin**: Database management interface
- **MailHog**: Email testing and debugging
- **Code Quality**: PHPCS, PHPStan, Psalm configurations
- **Traefik Dashboard**: `http://localhost:8080`

### Site Isolation
- Separate databases per site
- Independent WordPress installations
- Isolated file systems
- Individual SSL certificates

---

## 📚 Documentation

- [Current Platform Status](CURRENT_PLATFORM_STATUS.md)
- [Architecture Overview](ARCHITECTURE.md)
- [Platform Summary](PLATFORM_SUMMARY.md)
- [Site Management Guide](docs/SITE_MANAGEMENT.md)

---

## 🎉 Getting Started

1. **Clone the repository**
2. **Start the platform**: `docker-compose -f docker-compose-nip-fixed.yml up -d`
3. **Access WordPress sites**: Visit `xandar.127.0.0.1.nip.io` and `asgard.127.0.0.1.nip.io`
4. **Create new sites**: `./scripts/manage-sites.sh create myproject`
5. **Manage databases**: Visit `phpmyadmin.127.0.0.1.nip.io`
6. **Test emails**: Check `mailhog.127.0.0.1.nip.io`
7. **Start developing**: Build amazing WordPress projects!

---

## 🏆 Benefits

- **No Port Management**: Clean domain-based access
- **SSL/TLS Ready**: Production-like development
- **Unlimited Sites**: Create as many projects as needed
- **Isolated Environments**: No cross-contamination
- **Complete Toolchain**: Everything you need for WordPress development
- **Easy Management**: Simple commands for all operations

---

## 🎯 Perfect For

- **WordPress Plugin Development**
- **WordPress Theme Development**
- **Client Project Development**
- **WordPress Core Contribution**
- **Learning WordPress Development**
- **Testing and Experimentation**

---

## 🚀 **Your WordPress Matrix is Ready!**

**Start building amazing WordPress projects with a world-class development environment!**

For questions or support, check the documentation or create an issue.

**Happy coding!** ✨