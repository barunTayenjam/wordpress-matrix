# AGENTS.md - WordPress Development Platform Guide

This document serves as a comprehensive guide for agents working with the WordPress Development Platform repository.

## Project Overview

This is a streamlined WordPress development environment that supports multiple WordPress instances with Docker, designed for professional WordPress development. The platform includes code quality tools, monitoring, caching layers, and simplified management.

## Directory Structure

```
wordpress-matrix/
├── wp_*/                      # Dynamically created WordPress sites
├── config/                    # Configuration files for services
│   ├── nginx/                 # Nginx configurations
│   ├── phpcs/                 # PHP CodeSniffer config
│   ├── phpstan/              # PHPStan static analysis config
│   ├── phpunit/              # PHPUnit testing config
│   └── redis/                # Redis cache configuration
├── docker/                    # Docker-related files
├── docs/                      # Documentation
├── ssl-certs/                 # SSL certificates
└── logs/                      # Log files for all services
```

## Essential Commands

### Environment Management
```bash
./wp-simple setup          # Initial setup of the environment
./wp-simple start           # Start all services
./wp-simple stop            # Stop all services
./wp-simple restart         # Restart all services
./wp-simple status          # Show status of all services
./wp-simple clean           # Clean up unused Docker resources
```

### Site Management
```bash
./wp-simple list                    # List all WordPress sites
./wp-simple create <site-name>      # Create new WordPress site
./wp-simple start <site-name>       # Start specific site
./wp-simple stop <site-name>        # Stop specific site
./wp-simple remove <site-name>      # Remove site
./wp-simple info <site-name>        # Show site details
```

### Code Quality Tools
```bash
./wp-simple lint           # Run PHP CodeSniffer (WordPress standards)
./wp-simple fix            # Auto-fix CodeSniffer issues
./wp-simple analyse         # Run PHPStan static analysis
./wp-simple test           # Run PHPUnit tests
./wp-simple quality        # Run all quality checks
./wp-simple check          # Run essential checks only
```

### Development Tools
```bash
./wp-simple shell wpcli              # Access WP-CLI container
./wp-simple shell composer           # Access Composer container
./wp-simple shell node               # Access Node.js container
./wp-simple logs <service>           # View service logs
```

## Key Configuration Files

### Environment Configuration
- `.env.example` - Template environment file
- `.env` - Active environment variables
- `.env.platform` - Platform-specific settings

### Docker Configuration
- `docker-compose.yml` - Main Docker services definition
- `docker/nginx/nginx-entrypoint.sh` - Nginx container initialization

### Code Quality Configuration
- `config/phpstan/phpstan.neon` - PHPStan configuration (Level 9, strict rules)
- `config/phpunit/phpunit.xml` - PHPUnit test configuration
- `config/security/security-scan.conf` - Security scanning rules

## Site Types

### Predefined Sites
- **xandar** - Primary development site
- **asgard** - Secondary development site

### Dynamic Sites
- Created with naming pattern: `wordpress_<sitename>`
- Can be created/removed dynamically
- Follow naming convention: alphanumeric, hyphens, underscores, starts with letter

## Code Quality Standards

### PHP Standards
- PHPStan Level 9 with strict rules
- WordPress Coding Standards enforced via PHP CodeSniffer
- Psalm static analysis for type checking
- PHP Mess Detector for code quality

### Testing
- PHPUnit for unit tests
- Coverage reports generated in `./tests/coverage/`

## Access URLs

### WordPress Sites
- xandar: https://xandar.127.0.0.1.nip.io
- sakaar: https://sakaar.127.0.0.1.nip.io
- Dynamic sites: https://<sitename>.127.0.0.1.nip.io

### Management Tools
- phpMyAdmin: https://phpmyadmin.127.0.0.1.nip.io
- MailHog: https://mailhog.127.0.0.1.nip.io
- Grafana: https://grafana.127.0.0.1.nip.io
- Traefik Dashboard: http://localhost:8080

## Common Workflows

### Creating a New WordPress Site
1. Use `./scripts/manage-sites.sh create <sitename>`
2. Site automatically gets:
   - WordPress core files
   - Database (named `<sitename>_db`)
   - Nginx configuration
   - Port assignment
   - Docker services

### Running Code Quality Checks
1. Use `./scripts/manage.sh quick-check` for essential checks
2. Use `./scripts/manage.sh quality` for comprehensive analysis
3. Fixes can be auto-applied with `./scripts/manage.sh fix`

### Accessing WordPress CLI
1. Use `./wp-dev shell wpcli`
2. Inside container, specify site path with `--path=/var/www/html/<sitename>`
3. Example: `wp plugin install query-monitor --activate --path=/var/www/html/xandar`

## Important Gotchas

### Site Management
- Predefined sites (xandar, asgard) cannot be removed
- Dynamic sites follow pattern `wordpress_<sitename>` in directories
- Each site needs unique port number
- Database names follow pattern `<sitename>_db`

### Environment Variables
- Always copy `.env.example` to `.env` before first use
- Environment variables are automatically loaded by scripts
- Port numbers are dynamically assigned for new sites

### Code Quality
- PHPStan is configured at strictest level (Level 9)
- WordPress globals are properly configured in PHPStan ignores
- Exclude paths are set for vendor, node_modules, cache directories

### Docker Architecture
- Uses Traefik as reverse proxy for domain-based routing
- Each WordPress site has:
  - PHP-FPM container
  - Nginx proxy container
  - Shared database and cache services
- Supporting services: db-primary, redis, memcached, phpmyadmin, mailhog

## Scripts Overview

### Main Scripts
- `wp-dev` - Primary CLI interface for environment management
- `scripts/manage.sh` - Environment management and code quality tools
- `scripts/manage-sites.sh` - WordPress site lifecycle management

### Utility Scripts
- `scripts/generate-dev-certs.sh` - SSL certificate generation
- `mysql_entrypoint.sh` - Database initialization

## Development Tips

### Hot Reload
- File changes in WordPress directories trigger automatic refresh
- Enabled by default via `ENABLE_HOT_RELOAD=true`

### XDebug
- Pre-configured for debugging
- Connect IDE to localhost:9003
- Path mapping: local files to `/var/www/html`

### Database Management
- Use phpMyAdmin at https://phpmyadmin.127.0.0.1.nip.io
- Credentials in `.env` file
- Automated backups can be enabled via `ENABLE_BACKUP=true`

## File Permissions

When working with WordPress files directly:
```bash
sudo chown -R $USER:$USER xandar sakaar wordpress_*
chmod -R 755 xandar sakaar wordpress_*
```

## Troubleshooting

### Services Won't Start
```bash
docker system prune -f
./wp-dev start
```

### Permission Issues
```bash
sudo chown -R $USER:$USER <site_directory>
```

### Database Connection Issues
```bash
./wp-dev restart db-primary
```

### Check Service Status
```bash
./wp-dev status
./scripts/manage.sh port-status
```

## Documentation Reference

- `docs/USAGE_GUIDE.md` - Complete usage guide
- `docs/QUICK_REFERENCE.md` - Commands and URLs
- `docs/WORDPRESS_INSTANCES.md` - Instance management
- `docs/ARCHITECTURE.md` - System design overview
- `docs/CODE_QUALITY.md` - Code quality practices
- `docs/DEBUGGING.md` - Debugging guide

## Simplified Version

For reduced complexity and easier onboarding, a simplified version is available:

### Key Files
- `wp-simple` - All-in-one management script
- `docker-compose.simple.yml` - Streamlined Docker configuration
- `.env.simple` - Simplified environment template
- `README_SIMPLIFIED.md` - Complete simplified version guide

### Quick Setup
```bash
cp .env.simple .env
cp docker-compose.simple.yml docker-compose.yml
chmod +x wp-simple
./wp-simple setup
./wp-simple create mysite
./wp-simple start
```

### Main Benefits
- 70% fewer commands to learn
- Single entry point (`wp-simple`)
- Lower resource usage
- Faster setup and startup
- Better error messages

### Core Commands
```bash
./wp-simple create <name>    # Create site
./wp-simple list              # List sites
./wp-simple start             # Start all
./wp-simple check             # Code quality
./wp-simple shell wp          # WordPress CLI
```

Choose the simplified version for:
- Faster development setup
- Lower learning curve
- Reduced resource requirements
- Simpler maintenance

Use the complex version for:
- Enterprise environments
- Advanced monitoring needs
- Complex multi-site architectures
- Full feature requirements