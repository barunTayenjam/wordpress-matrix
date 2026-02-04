# AGENTS.md - WordPress Development Platform Guide

This document serves as a comprehensive guide for agents working with the WordPress Development Platform repository.

## Project Overview

This is a streamlined WordPress development environment that supports multiple WordPress instances with Docker, designed for professional WordPress development. The platform includes code quality tools, monitoring, caching layers, and simplified management.

## Architecture

### Core Components

- **matrix** - Main management script (Bash)
- **docker-compose.yml** - Docker services configuration
- **frontend/** - Web-based management interface (Node.js)
- **scripts/** - Utility scripts for specific operations
- **config/nginx/** - Nginx configurations for each site

### Service Architecture

```
Host Machine (macOS/Linux)
├── Frontend (Node.js on port 8500)
├── Matrix Script (Bash)
└── Docker Containers:
    ├── WordPress Sites (wp_*, nginx_*)
    ├── Database (MySQL)
    ├── Cache (Redis)
    ├── phpMyAdmin
    └── Code Quality Tools (phpcs, phpstan)
```

## Directory Structure

```
wordpress-matrix/
├── wp_*/                      # WordPress sites
├── frontend/                  # Web management interface
│   ├── app.js                # Express server
│   ├── public/               # Static assets
│   ├── views/                # Handlebars templates
│   └── package.json          # Node dependencies
├── scripts/                   # Utility scripts
├── config/nginx/             # Nginx configurations
├── docker-compose.yml        # Main Docker configuration
├── matrix                    # Main management script
└── logs/                     # Application logs
```

## Essential Commands

### Environment Management
```bash
./matrix start           # Start all sites and frontend
./matrix stop            # Stop all services and frontend
./matrix restart         # Restart all services and frontend
./matrix status          # Show system status
./matrix clean           # Clean up unused Docker resources
```

### Site Management
```bash
./matrix list                    # List all WordPress sites
./matrix create <site-name>      # Create new WordPress site
./matrix start <site-name>       # Start specific site
./matrix stop <site-name>        # Stop specific site
./matrix remove <site-name>      # Remove site
./matrix info <site-name>        # Show site details
./matrix url <site-name>         # Show site URLs
```

### Code Quality Tools
```bash
./matrix check                    # Run code quality checks on all sites
./matrix check <site>             # Run checks on specific site
./matrix check <site> <path>      # Run checks on specific path
```

### Development Tools
```bash
./matrix shell wp            # Access WordPress container shell
./matrix logs <site>         # Show site logs
./matrix clone <src> <dst>   # Clone existing site
./matrix reset <name>        # Reset site to fresh install
```

### Frontend Management
```bash
./matrix frontend start     # Start web interface
./matrix frontend stop      # Stop web interface
./matrix frontend restart   # Restart web interface
./matrix frontend status    # Check frontend status
```

## Site Types

### Dynamic Sites
- Created with naming pattern: `wordpress_<sitename>` → `wp_<sitename>`
- Can be created/removed dynamically
- Naming convention: alphanumeric, hyphens, underscores, starts with letter

### Port Assignment
- Sites automatically get ports starting from 8100
- phpMyAdmin: 8200
- Frontend: 8500
- Database: 3306

## Code Quality Standards

### PHP Standards
- PHPStan Level 9 with strict rules
- WordPress Coding Standards enforced via PHP CodeSniffer
- Psalm static analysis for type checking

### Testing
- PHPUnit for unit tests
- Coverage reports generated in `./tests/coverage/`

## Access URLs

### WordPress Sites
- Direct access: http://localhost:8100, 8201, 8202, etc.
- Each site gets unique port assignment

### Management Tools
- Frontend Dashboard: http://localhost:8500
- phpMyAdmin: http://localhost:8200

## Common Workflows

### Creating a New WordPress Site
```bash
./matrix create mysite
```

This automatically:
1. Creates WordPress core files in `wp_mysite/`
2. Creates database named `mysite_db`
3. Generates Nginx configuration
4. Assigns port (8100+)
5. Starts Docker services

### Running Code Quality Checks
```bash
# All sites
./matrix check

# Specific site
./matrix check mysite

# Specific path (faster)
./matrix check mysite wp-content/themes/custom-theme
```

### Accessing WordPress CLI
```bash
./matrix shell wp
# Inside container, specify site path:
wp plugin install query-monitor --activate --path=/var/www/html/mysite
```

## Important Gotchas

### Site Management
- Sites cannot be named "frontend", "matrix", or other reserved words
- Site directories follow pattern `wp_<sitename>`
- Database names follow pattern `<sitename>_db`
- Removing a site deletes all files and database

### Environment Variables
- Loaded from `.env` file if it exists
- Port numbers dynamically assigned
- Database credentials in `.env` file

### Code Quality
- PHPStan configured at Level 9 (strictest)
- WordPress globals configured in PHPStan ignores
- Exclude paths set for vendor, node_modules, cache directories
- Checks on ALL sites can take 2+ minutes

### Frontend
- Runs as host Node.js process (NOT in Docker)
- Manages Docker via matrix script execution
- Can start/stop sites and run code quality checks
- Access via web browser at http://localhost:8500

## Docker Architecture

### Service Containers
- **wp_*** - WordPress PHP-FPM containers
- **nginx_*** - Nginx reverse proxy for each site
- **db** - MySQL database server
- **redis** - In-memory cache
- **phpmyadmin** - Database management UI
- **phpcs/phpstan** - Code quality tools (on-demand)

### Networks
- `wp-net` - Internal Docker network for service communication

## Frontend Architecture

### Technology Stack
- Node.js with Express
- Handlebars templating
- Axios for HTTP requests
- Runs on host (not containerized)

### API Endpoints
- `GET /` - Dashboard UI
- `GET /api/sites` - List all sites
- `POST /api/sites/create` - Create new site
- `POST /api/sites/start` - Start site
- `POST /api/sites/stop` - Stop site
- `POST /api/environment/check` - Run code quality checks
- `GET /health` - Health check

### Process Management
- PID tracked in `.frontend.pid`
- Logs written to `logs/frontend.log`
- Managed by `matrix frontend` commands

## Troubleshooting

### Services Won't Start
```bash
./matrix stop
docker system prune -f
./matrix start
```

### Frontend Issues
```bash
./matrix frontend restart
tail -f logs/frontend.log
```

### Database Connection Issues
```bash
./matrix restart db
```

### Port Conflicts
```bash
lsof -ti:8500 | xargs kill -9  # Clear frontend port
```

## Development Tips

### Hot Reload
- File changes in WordPress directories trigger automatic refresh
- Enabled by default

### XDebug
- Pre-configured for debugging
- Connect IDE to localhost:9003
- Path mapping required

### Database Management
- Use phpMyAdmin at http://localhost:8200
- Credentials in `.env` file
- Automated backups available via scripts

## File Permissions

When working with WordPress files directly:
```bash
sudo chown -R $USER:$USER wp_*
chmod -R 755 wp_*
```

## Security Best Practices

- Frontend runs as non-root user
- No docker socket mounting required
- Matrix script validates site names
- Database credentials not hardcoded
- SSL certificates in `ssl-certs/` directory

## Performance Optimization

### Caching
- Redis for object caching
- Nginx micro-caching enabled
- OPcache for PHP

### Resource Limits
- PHP memory limit: 512M
- Container resource constraints in docker-compose.yml
- Automatic cleanup of unused resources

## Scripts Overview

### Available Scripts
- `scripts/backup.sh` - Backup sites
- `scripts/clone.sh` - Clone sites
- `scripts/reset.sh` - Reset sites
- `scripts/update-core.sh` - Update WordPress core
- `scripts/cache-clear.sh` - Clear caches
- `scripts/search-replace.sh` - Database search/replace
- `scripts/health-check.sh` - System health check

## Documentation Reference

- `README.md` - Quick start guide
- `AGENTS.md` - This file - comprehensive guide

## Support

For issues or questions:
1. Check troubleshooting section
2. Review logs in `logs/` directory
3. Run `./matrix status` for system overview
4. Check frontend dashboard at http://localhost:8500

## Best Practices for Agents

1. **Always verify current state** - Run `./matrix status` before making changes
2. **Use specific commands** - Prefer `./matrix check <site>` over `./matrix check`
3. **Monitor logs** - Check `logs/frontend.log` and Docker logs
4. **Test changes** - Verify sites work after operations
5. **Document changes** - Update this guide when adding features
6. **Backup first** - Use scripts/backup.sh before major changes
