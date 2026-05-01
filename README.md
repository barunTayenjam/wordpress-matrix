# WordPress Development Platform

A streamlined WordPress development environment with Docker/Podman support, comprehensive code quality tools, web-based management interface, and simplified management.

## Key Features

- **Simplified Management**: All-in-one `matrix` script for easy site management
- **Web Interface**: Beautiful dashboard at http://localhost:8500 for visual management
- **Code Quality Tools**: PHPStan, PHP CodeSniffer for WordPress development
- **Multi-Site Environment**: Create and manage multiple WordPress instances
- **Container Runtime Support**: Full Docker and Podman support
- **Real-time Monitoring**: Track site status and health
- **Database Operations**: Import/export SQL dumps, backups, restore

## Requirements

- Docker OR Podman with docker-compose/podman-compose
- Node.js (for frontend web interface)

## Quick Start

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

# Access the web dashboard
open http://localhost:8500

# Access your site (port shown after creation)
open http://localhost:8201
```

After creating a site, the command output shows the direct access URL (e.g., http://localhost:8201).

## Documentation

- **[AGENTS.md](AGENTS.md)** - Comprehensive guide for AI agents and developers
- **Web Dashboard** - Interactive management interface at http://localhost:8500

## Common Tasks

### Site Management

```bash
# Create a new site (default PHP 8.3)
./matrix create blog

# Create a site with specific PHP version
./matrix create oldsite --php-version=7.4
./matrix create testsite --php-version=8.1

# List all sites
./matrix list

# Start core services (database, redis, phpMyAdmin, frontend)
./matrix start

# Start specific site
./matrix start blog

# Stop specific site
./matrix stop blog

# Restart a site
./matrix restart blog

# View site info
./matrix info blog

# Show site URL
./matrix url blog

# Remove a site
./matrix remove blog --yes

# Edit site configuration (PHP version)
./matrix edit blog --php-version=8.2
```

### Backup & Restore

```bash
# Backup a site
./matrix backup blog

# Restore from backup
./matrix restore blog backups/blog-20260501.tar.gz
```

### Database Operations

```bash
# Export database
./matrix export-db blog

# Export to specific file
./matrix export-db blog mydump.sql

# Import database
./matrix import-db blog dumpfile.sql
```

### Site Operations via Web Dashboard

The frontend at http://localhost:8500 provides:
- **Start/Stop/Restart** sites with one click
- **Create** new sites with PHP version selector
- **Backup** sites to tar.gz archives
- **Edit** PHP version
- **Clone** existing sites
- **Reset** to fresh WordPress install
- **Export/Import** SQL databases
- **View** site logs
- **Delete** sites

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

### Shell Access

```bash
# Access WordPress container shell
./matrix shell wp

# Access database
./matrix shell db

# Access nginx container
./matrix shell nginx

# Check PHP version in running container
podman exec wp_blog php -v
# or with docker:
docker exec wp_blog php -v
```

## Access URLs

### Web Dashboard
- **Dashboard**: http://localhost:8500

### WordPress Sites
Sites are accessible on sequentially assigned ports starting from 8201 (8200 is reserved for phpMyAdmin):
- First site: http://localhost:8201
- Second site: http://localhost:8202
- And so on...

The site URL is displayed after running `./matrix create <name>` or `./matrix url <name>`. You can also view all site URLs via the web dashboard.

### Management Tools
- **phpMyAdmin**: http://localhost:8200
- **Database**: localhost:3306

## Features

### PHP Version Management

```bash
# Supported PHP versions
./matrix create site74 --php-version=7.4   # Legacy WordPress testing
./matrix create site80 --php-version=8.0   # PHP 8.0 support
./matrix create site81 --php-version=8.1   # PHP 8.1 support
./matrix create site82 --php-version=8.2   # PHP 8.2 support
./matrix create site83 --php-version=8.3   # Latest stable (default)
```

Each site can run a different PHP version, allowing you to:
- Test plugins/themes across multiple PHP versions
- Debug compatibility issues
- Gradually migrate legacy sites to newer PHP

### Container Services
- **MySQL 8.0**: Database server with health checks
- **Redis**: In-memory caching and session storage
- **Nginx**: High-performance web server for each site
- **Multiple PHP Versions**: Support for PHP 7.4, 8.0, 8.1, 8.2, 8.3 (default: 8.3)
- **phpMyAdmin**: Database management interface

### Web Dashboard Features
- **Site Management**: Create, start, stop, restart, remove sites
- **Backup & Restore**: Full site backup/restore functionality
- **Database Operations**: Import/export SQL dumps
- **Edit Configuration**: Change PHP version per site
- **Clone Sites**: Duplicate existing sites
- **Reset Sites**: Reset to fresh WordPress installation
- **View Logs**: Real-time site log streaming
- **Real-time Status**: View all sites and services at a glance
- **Code Quality**: Run checks directly from the UI
- **Modern Interface**: Responsive, clean design with dark mode

## Troubleshooting

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

# View site logs
./matrix logs <site-name>
```

### Getting Help
1. **Check Status**: `./matrix status`
2. **View Dashboard**: http://localhost:8500
3. **Review Documentation**: Check [AGENTS.md](AGENTS.md)

## Project Structure

```
wordpress-matrix/
├── matrix                 # Main management script
├── docker-compose.yml     # Docker services configuration
├── frontend/              # Web management interface
│   ├── app.js            # Express server
│   ├── public/           # Static assets & JS
│   └── views/            # Handlebars templates
├── scripts/              # Utility scripts
├── config/nginx/         # Nginx configurations
├── logs/                 # Application logs
└── wp_*/                # WordPress site directories
```

## Getting Started Checklist

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
- [ ] Use backups before major changes

## Port Configuration

| Service | Port |
|---------|------|
| Frontend Dashboard | 8500 |
| phpMyAdmin | 8200 |
| WordPress Sites | 8201+ |
| Database | 3306 |

## Security

- Frontend runs as non-root user
- No docker socket mounting required
- Database credentials in `.env` file
- Site name validation prevents conflicts

## Quick Reference

```bash
./matrix create mysite          # Create site (PHP 8.3)
./matrix create mysite --php-version=8.1  # PHP 8.1
./matrix start                 # Start all services
./matrix start mysite          # Start specific site
./matrix stop mysite           # Stop specific site
./matrix restart mysite        # Restart specific site
./matrix remove mysite --yes   # Remove site
./matrix backup mysite         # Backup site
./matrix restore mysite backups/myfile.tar.gz
./matrix export-db mysite      # Export database
./matrix import-db mysite dump.sql
./matrix edit mysite --php-version=8.2
./matrix logs mysite           # View logs
./matrix check mysite          # Code quality check
./matrix list                  # List sites
./matrix status                # System status
./matrix frontend start        # Start web UI
```

## License

MIT License - feel free to use this for your projects

## Happy Developing!

**Quick Start**: `chmod +x matrix && ./matrix start && ./matrix create mysite && ./matrix start mysite && open http://localhost:8500`