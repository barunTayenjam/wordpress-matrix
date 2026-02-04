# 🚀 WordPress Development Platform

A streamlined WordPress development environment with Docker support, comprehensive code quality tools, web-based management interface, and simplified management.

## ✨ Key Features

- **⚡ Simplified Management**: All-in-one `matrix` script for easy site management
- **🌐 Web Interface**: Beautiful dashboard at http://localhost:8500 for visual management
- **🧪 Code Quality Tools**: PHPStan, PHP CodeSniffer for WordPress development
- **🔧 Multi-Site Environment**: Create and manage multiple WordPress instances
- **🐳 Docker Support**: Full Docker and docker-compose support
- **📊 Real-time Monitoring**: Track site status and health

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/wordpress-matrix.git
cd wordpress-matrix

# Make script executable
chmod +x matrix

# Start core services (database, redis, phpMyAdmin, frontend)
./matrix start

# Create your first site
./matrix create mysite

# Start your site
./matrix start mysite

# Access the web dashboard
open http://localhost:8500
```

## 📖 Documentation

- **[AGENTS.md](AGENTS.md)** - Comprehensive guide for AI agents and developers
- **Web Dashboard** - Interactive management interface at http://localhost:8500

## 🎯 Common Tasks

### Site Management
```bash
# Create a new site
./matrix create blog

# List all sites
./matrix list

# Start core services (database, redis, phpMyAdmin, frontend)
./matrix start

# Start specific site
./matrix start blog

# Stop specific site
./matrix stop blog

# Stop all services (including frontend)
./matrix stop

# Remove a site
./matrix remove blog
```

### Code Quality Checks
```bash
# Check all sites
./matrix check

# Check specific site
./matrix check blog

# Check specific path
./matrix check blog wp-content/themes/custom-theme
```

### Frontend Management
```bash
# Start web interface
./matrix frontend start

# Stop web interface
./matrix frontend stop

# Check frontend status
./matrix frontend status
```

### WordPress CLI
```bash
# Access WordPress CLI
./matrix shell wp

# Install plugins
wp plugin install query-monitor --activate --path=/var/www/html/mysite

# Database operations
wp db export backup.sql --path=/var/www/html/mysite
```

## 🌐 Access URLs

### Web Dashboard
- **Dashboard**: http://localhost:8500

### WordPress Sites
Sites are accessible on sequentially assigned ports:
- First site: http://localhost:8100
- Second site: http://localhost:8101
- Third site: http://localhost:8102
- And so on...

### Management Tools
- **phpMyAdmin**: http://localhost:8200
- **Database**: localhost:3306

## 🔧 Features

### Code Quality Tools
- **PHPStan Level 9**: Strict static analysis
- **PHP CodeSniffer**: WordPress coding standards
- **Automated Checks**: Run on specific sites or paths

### Development Tools
- **WordPress CLI**: Pre-configured WP-CLI access
- **Database Management**: phpMyAdmin integration
- **Web Dashboard**: Visual site management
- **API Endpoints**: Programmatic control

### Container Services
- **MySQL 8.0**: Database server with health checks
- **Redis**: In-memory caching and session storage
- **Nginx**: High-performance web server for each site
- **PHP 8.3**: Latest PHP with WordPress optimizations
- **phpMyAdmin**: Database management interface

### Web Dashboard Features
- **Site Management**: Create, start, stop, remove sites
- **Real-time Status**: View all sites and services at a glance
- **Code Quality**: Run checks directly from the UI
- **Environment Control**: Start/stop entire environment
- **Modern Interface**: Responsive, clean design

## 🛠️ Troubleshooting

### Quick Fixes
```bash
# Services won't start
./matrix clean
./matrix start

# Database issues
./matrix restart db

# Frontend issues
./matrix frontend restart

# Port conflicts
lsof -ti:8500 | xargs kill -9  # Clear frontend port
```

### Logs
```bash
# View frontend logs
tail -f logs/frontend.log

# View Docker logs
./matrix logs <site-name>
```

### Getting Help
1. **Check Status**: `./matrix status`
2. **View Dashboard**: http://localhost:8500
3. **Review Documentation**: Check [AGENTS.md](AGENTS.md)

## 📂 Project Structure

```
wordpress-matrix/
├── matrix                 # Main management script
├── docker-compose.yml     # Docker services configuration
├── frontend/             # Web management interface
│   ├── app.js           # Express server
│   ├── public/          # Static assets
│   └── views/           # Handlebars templates
├── scripts/             # Utility scripts
├── config/nginx/        # Nginx configurations
├── logs/                # Application logs
└── wp_*/               # WordPress site directories
```

## 🚀 Getting Started Checklist

### First-Time Setup
- [ ] Clone repository
- [ ] Make matrix executable: `chmod +x matrix`
- [ ] Start core services: `./matrix start`
- [ ] Create first site: `./matrix create mysite`
- [ ] Start your site: `./matrix start mysite`
- [ ] Open dashboard: http://localhost:8500
- [ ] Access your site at assigned port

### Development Workflow
- [ ] Create sites as needed
- [ ] Use web dashboard for visual management
- [ ] Run code quality checks before commits
- [ ] Monitor logs when troubleshooting

## 📊 Port Configuration

| Service | Port Range |
|---------|-----------|
| Frontend Dashboard | 8500 |
| phpMyAdmin | 8200 |
| WordPress Sites | 8100+ |
| Database | 3306 |

## 🔒 Security

- Frontend runs as non-root user
- No docker socket mounting required
- Database credentials in `.env` file
- Site name validation prevents conflicts

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

MIT License - feel free to use this for your projects

## 🎉 Happy Developing!

**Quick Start**: `chmod +x matrix && ./matrix start && ./matrix create mysite && ./matrix start mysite && open http://localhost:8500`
