# AGENTS.md - WordPress Development Platform Guide

This document serves as a comprehensive guide for agents working with the WordPress Development Platform repository.

## Project Overview

This is a streamlined WordPress development environment that supports multiple WordPress instances with Docker or Podman, designed for professional WordPress development. The platform includes code quality tools, monitoring, caching layers, a web dashboard, and simplified management.

The current release has been audit-hardened: core `matrix` CLI paths use live Docker/Podman state as a fallback when `docker-compose.yml` is missing or stale, site names are validated consistently, JSON output is parseable, and database/WP-CLI flows run without requiring a long-running `wp-cli` service.

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
├── wp_*/                      # WordPress sites; wp_content is shared scaffolding content, not a site
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
./matrix start           # Start core services (db, redis, phpmyadmin, frontend)
./matrix stop            # Stop all services and frontend
./matrix restart         # Restart all services and frontend
./matrix status          # Show system status
scripts/health-check.sh  # Runtime health check for containers, DB, Redis, ports, and logs
./matrix clean           # Clean up unused Docker resources
```

### Site Management
```bash
./matrix list                                    # List all WordPress sites
./matrix create <site-name>                      # Create new WordPress site (PHP 8.3)
./matrix create <site-name> --php-version=7.4    # Create site with PHP 7.4
./matrix create <site-name> --php-version=8.1    # Create site with PHP 8.1
./matrix start <site-name>                       # Start specific site
./matrix stop <site-name>                        # Stop specific site
./matrix remove <site-name>                      # Remove site
./matrix info <site-name>                        # Show site details
./matrix info <site-name> --json                 # Show machine-readable site details
./matrix url <site-name>                         # Show site URLs
./matrix rest <site-name>                        # Show WordPress REST API metadata
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
./matrix shell db            # Access database shell
./matrix shell nginx         # Access nginx shell
./matrix wp <site> <args>    # Run WP-CLI via on-demand wordpress:cli container
./matrix logs <site>         # Show site logs
./matrix logs db             # Show DB logs
./matrix logs redis          # Show Redis logs
./matrix logs phpmyadmin     # Show phpMyAdmin logs
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
- Sites automatically get ports starting from 8201
- phpMyAdmin: 8200
- Frontend: 8500
- Database: 3306
- Port allocation checks Compose config, live container port bindings, and local listeners where available

### PHP Version Support
- **Supported versions**: PHP 7.4, 8.0, 8.1, 8.2, 8.3
- **Default version**: PHP 8.3
- Each site can run a different PHP version
- Specify PHP version at site creation with `--php-version=X.X` flag
- Useful for testing compatibility across PHP versions
- Migrate legacy sites gradually by testing side-by-side

## Code Quality Standards

### PHP Standards
- PHPStan Level 9 with strict rules
- WordPress Coding Standards enforced via PHP CodeSniffer
- Psalm static analysis for type checking

### Testing
- PHPUnit for unit tests
- Frontend API tests use Jest and Supertest from `frontend/`
- Coverage reports generated in `./tests/coverage/`
- Current verified release bar: `bash -n matrix`, `bash -n scripts/*.sh`, `npm --prefix frontend test`, `./matrix * --json | python3 -m json.tool`, and `scripts/health-check.sh`

## Access URLs

### WordPress Sites
- Direct access: http://localhost:8201, 8202, 8203, etc.
- Each site gets unique port assignment

### Management Tools
- Frontend Dashboard: http://localhost:8500
- phpMyAdmin: http://localhost:8200

## Common Workflows

### Creating a New WordPress Site
```bash
# Create with default PHP (8.3)
./matrix create mysite

# Create with specific PHP version
./matrix create legacy-site --php-version=7.4
./matrix create modern-site --php-version=8.2
```

This automatically:
1. Creates WordPress core files in `wp_mysite/`
2. Creates database named `mysite_db`
3. Generates Nginx configuration
4. Assigns port (8201+)
5. Pulls appropriate Docker image with specified PHP version
6. Starts Docker services

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
# Preferred: run WP-CLI directly for a site
./matrix wp mysite core version
./matrix wp mysite plugin list
./matrix wp mysite plugin install query-monitor --activate

# Check PHP version of a running site
docker exec wp_mysite php -v
```

## Important Gotchas

### Site Management
- Sites cannot be named "frontend", "matrix", or other reserved words
- Site directories follow pattern `wp_<sitename>`
- `wp_content/` is shared scaffolding content and must not be treated as a site
- Database names follow pattern `<sitename>_db`
- Removing a site deletes all files and database
- **IMPORTANT**: `./matrix start` only starts core services (db, redis, phpmyadmin, frontend)
- Sites must be started individually with `./matrix start <site>` after environment starts
- This gives you control over which sites run at any time

### Environment Variables
- Loaded from `.env` file if it exists
- Port numbers dynamically assigned
- Database credentials in `.env` file
- MySQL database creation/reset requires root credentials; routine WP access uses the configured WordPress DB user

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

### PHP Version Management
- Site's PHP version is stored in docker-compose.yml
- Check PHP version: `grep "wp_sitename:" -A 3 docker-compose.yml`
- Change PHP version: Edit docker-compose.yml and `./matrix restart <sitename>`
- Supported: wordpress:php7.4-fpm, wordpress:php8.0-fpm, wordpress:php8.1-fpm, wordpress:php8.2-fpm, wordpress:php8.3-fpm
- If Compose state is stale or missing, status/log/info/shell paths should fall back to live container inspection rather than reporting false stopped states

## Docker Architecture

### Service Containers
- **wp_*** - WordPress PHP-FPM containers (version-specific images: wordpress:phpX.X-fpm)
- **nginx_*** - Nginx reverse proxy for each site
- **db** - MySQL database server
- **redis** - In-memory cache
- **phpmyadmin** - Database management UI
- **phpcs/phpstan** - Code quality tools (on-demand)
- **wp_cli / wordpress:cli** - WP-CLI runs on demand and joins the live DB container network

### Networks
- `wp-net` - Intended Compose network for service communication
- When invoking one-off tool containers, discover the actual `wp_db` network dynamically instead of assuming the literal `wp-net` name

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

The Express app validates site names, PHP versions, relative file paths, and allowed actions before spawning `matrix`. JSON routes should call `matrix` with `--json` and parse structured output instead of scraping human text.

### Process Management
- PID tracked in `.frontend.pid`
- Logs written to `logs/frontend.log`
- Managed by `matrix frontend` commands

## Troubleshooting

### Services Won't Start
```bash
./matrix status
scripts/health-check.sh
./matrix start
```

### Frontend Issues
```bash
./matrix frontend restart
tail -f logs/frontend.log
```

### Database Connection Issues
```bash
scripts/health-check.sh
./matrix logs db
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
- Configured per site with `./matrix xdebug <site>`
- Xdebug settings are written to `.user.ini`, not `wp-config.php`
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

Script implementation notes:
- Prefer `$CONTAINER_RUNTIME exec wp_db ...` for DB operations that must work even if Compose metadata is stale.
- Use `mysqldump --no-tablespaces` to avoid MySQL `PROCESS` privilege failures.
- Use shared `run_wp_cli` for WP-CLI operations instead of `docker-compose exec wp-cli`.

Site state seam (`scripts/helpers.sh`):
- `site_state <site>` is the single interface over Compose metadata + live container state. Returns `present=`/`running=`/`port=`/`php=`/`stack=` key=value lines. Resolution: Compose first, live container fallback.
- `site_in_compose <site>` is the canonical anchored `wp_<site>:` presence check in `docker-compose.yml`. Use it instead of ad-hoc `grep` calls.
- `compose_ps_names`, `container_is_running`, `compose_or_container_running` also live in `scripts/helpers.sh`; `matrix` and `scripts/*.sh` share them.
- Offline tests for this seam: `tests/bash/site-state-test.sh` (stubbed Docker + Compose, no daemon required).

## Documentation Reference

- `README.md` - Quick start guide
- `AGENTS.md` - This file - comprehensive guide

## Frontend Testing

### Dashboard Features
- **Dashboard Tab**: Stats display (running/stopped/services), Quick Actions (Start All, Stop All, Restart, Code Quality, Clean), Auto-refresh every 30 seconds
- **Sites Tab**: Site cards with status badges, action buttons (Start, Stop, Restart, Check, Backup, More), search/filter controls, sort options
- **Site Flyout**: Opens on site name click, shows site details (URL, PHP, Port), health check, lifecycle controls, information buttons, database operations, maintenance actions, advanced options, WP-CLI
- **Services Tab**: Table showing all services with status (Database, Redis, phpMyAdmin, PHP CodeSniffer, PHPStan, WP-CLI)
- **Terminal Tab**: Matrix CLI terminal interface (requires WebSocket connection for command execution)
- **Frontend Tab**: Status display with Open Dashboard link, control buttons (Start, Stop, Restart, Status)
- **Activity Tab**: Activity log table with timestamps, actions, and details

### Known Issues
- Terminal commands show "Network error" when WebSocket connection is not available (expected behavior)
- Flyout overlay may occasionally block clicks on "New Site" button (FIXED: added click-outside-to-close handler and z-index fix)

### Testing Commands
```bash
# Run frontend tests
npm --prefix frontend test

# Start frontend for manual testing
./matrix frontend start

# Check frontend status
./matrix frontend status
```

## Support

For issues or questions:
1. Check troubleshooting section
2. Review logs in `logs/` directory
3. Run `./matrix status` for system overview
4. Check frontend dashboard at http://localhost:8500

## Best Practices for Agents

1. **Always verify current state** - Run `./matrix status` before making changes
2. **Run health check for runtime issues** - Use `scripts/health-check.sh` when Docker/DB/Redis/port state is unclear
3. **Use specific commands** - Prefer `./matrix check <site>` over `./matrix check`
4. **Monitor logs** - Check `logs/frontend.log`, `./matrix logs <site>`, and service logs
5. **Test changes** - Verify sites work after operations and validate JSON with `python3 -m json.tool`
6. **Document changes** - Update this guide when adding features
7. **Backup first** - Use `./matrix backup <site>` or `scripts/backup.sh` before major changes
8. **Do not treat smoke-tested as guaranteed bug-free** - Use accurate release language such as "no known bugs in audited flows"

## Agent skills

### Issue tracker

Not configured — issue-tracker-dependent skills (`to-issues`, `triage`, `to-prd`) are unavailable.

### Triage labels

Not configured — no issue tracker to apply labels to.

### Domain docs

Single-context layout. See `docs/agents/domain.md`.

### Knowledge graph

This repo has a pre-built knowledge graph at `.understand-anything/knowledge-graph.json` (160 nodes, 256 edges, 6 layers — CLI Core, Frontend Application, Utility Scripts, Infrastructure, Configuration, Documentation & Planning). Use it with `understand`-family skills for architecture exploration, component relationships, and onboarding. Generated by understand-anything; update with `touch .understand-anything/stale` and re-run the skill.
