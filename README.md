# 🚀 WordPress Matrix

*A streamlined and powerful WordPress development environment.*

This repository provides a lightweight, developer-focused setup for everyday coding. It's built on Docker for speed, reliability, and consistency, and it includes all the essential tools for modern WordPress development.

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd wordpress-matrix
```

### 2. Start the Environment
```bash
./scripts/manage.sh start
```
This command will start all the necessary services and run health checks to ensure everything is running correctly.

### 3. Access Your Sites
- **WordPress 1**: [http://wordpress1.127.0.0.1.nip.io](http://wordpress1.127.0.0.1.nip.io)
- **WordPress 2**: [http://wordpress2.127.0.0.1.nip.io](http://wordpress2.127.0.0.1.nip.io)
- **Traefik Dashboard**: [http://traefik.127.0.0.1.nip.io](http://traefik.127.0.0.1.nip.io)
- **phpMyAdmin**: [http://phpmyadmin.127.0.0.1.nip.io](http://phpmyadmin.127.0.0.1.nip.io)
- **MailHog**: [http://mailhog.127.0.0.1.nip.io](http://mailhog.127.0.0.1.nip.io)

### Default Credentials
- **WordPress Admin**: `admin` / `admin`
- **MySQL Root**: `SecureRoot2024!`
- **phpMyAdmin**: `root` / `SecureRoot2024!`

---

## 🛠️ Environment Management

Use the `manage.sh` script to control your environment. This is the central tool for all operations.

```bash
# Start the environment (with health checks)
./scripts/manage.sh start

# Stop the environment
./scripts/manage.sh stop

# Restart the environment
./scripts/manage.sh restart

# Check the status of all services
./scripts/manage.sh status

# View the logs of a specific service
./scripts/manage.sh logs wordpress1

# Run a WP-CLI command on a specific site
./scripts/manage.sh wp wordpress1 plugin list

# Run code quality checks
./scripts/manage.sh quality

# Run quick essential checks
./scripts/manage.sh quick-check
```

## 🎯 Code Quality Tools

The Ultimate WordPress Development Matrix includes a comprehensive suite of code quality tools:

```bash
# Run all quality checks (recommended before commits)
./scripts/manage.sh quality

# Individual tools
./scripts/manage.sh lint      # PHP Code Sniffer (WordPress Standards)
./scripts/manage.sh fix       # Auto-fix PHPCS issues
./scripts/manage.sh analyse   # PHPStan Level 9 static analysis
./scripts/manage.sh phpmd     # PHP Mess Detector
./scripts/manage.sh psalm     # Psalm static analysis
./scripts/manage.sh test      # PHPUnit tests with coverage

# Quick check (PHPCS + PHPStan only)
./scripts/manage.sh quick-check
```

### If You Encounter Image Errors

If you have issues with your Docker images, you can use the `fix-images.sh` script to refresh them.

```bash
./scripts/fix-images.sh
```

---

## ✨ Features

### **Core WordPress Development**
- **WordPress**: Two instances for multi-site development
- **Nginx**: High-performance web server with unified configuration
- **MySQL**: The world's most popular open-source database
- **Redis & Memcached**: For powerful caching
- **WP-CLI**: Manage your WordPress sites from the command line
- **XDebug**: Step-by-step debugging with VS Code integration

### **Code Quality Suite (Level 9)**
- **PHP Code Sniffer**: WordPress coding standards enforcement
- **PHPStan**: Level 9 static analysis with WordPress rules
- **PHP Mess Detector**: Code smell and complexity analysis
- **Psalm**: Advanced static analysis and type checking
- **PHPUnit**: Unit testing with WordPress test framework

### **Development Tools**
- **MailHog**: E-mail testing tool
- **phpMyAdmin**: Web-based database management
- **Hot Reload**: Automatic browser refreshing on file changes
- **Composer**: PHP dependency management
- **Node.js/NPM**: Frontend build tools and package management

---

## 📚 Detailed Documentation

For more in-depth information, please refer to the `docs` directory:

- **[Code Quality Tools](docs/CODE_QUALITY.md)** - Comprehensive guide to all quality tools
- **[Debugging with XDebug](docs/DEBUGGING.md)** - Step-by-step debugging setup
- **[Platform Compatibility](docs/PLATFORM_COMPATIBILITY.md)** - System requirements
- **[Usage Guide](docs/USAGE_GUIDE.md)** - Complete usage instructions
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command reference
- **[Architecture Overview](ARCHITECTURE.md)** - System architecture details

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository.
2. Create a new feature branch.
3. Make your changes and commit them.
4. If applicable, add tests to cover your changes.
5. Submit a pull request.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

A special thanks to **Rovo Dev** for the original architecture and to all the open-source communities that make this project possible.

---

**Originally architected by Rovo Dev - Senior Architect**  
**Maintained and enhanced by Barun**

For support, please open an issue or contact the development team.