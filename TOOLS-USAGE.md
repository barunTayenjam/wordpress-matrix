# WordPress Matrix — Dev Tools Guide

## WP-CLI

WP-CLI is a command-line interface for WordPress. Run commands through the `matrix` script.

### Basic Usage

```bash
# Run any WP-CLI command for a site
./matrix wp <site-name> <command>

# Examples
./matrix wp su26 core version
./matrix wp su26 plugin list
./matrix wp su26 plugin install query-monitor --activate
./matrix wp su26 post list --post_type=post --post_status=publish
./matrix wp su26 option get siteurl
./matrix wp su26 user list
```

### Site Management

```bash
# Install WordPress core
./matrix wp su26 core install \
  --url="http://localhost:8202" \
  --title="My Site" \
  --admin_user=admin \
  --admin_password=password \
  --admin_email=admin@example.com

# Update WordPress core
./matrix wp su26 core update
./matrix wp su26 core update-db

# Check database version
./matrix wp su26 core version --extra
```

### Plugins & Themes

```bash
# List plugins
./matrix wp su26 plugin list
./matrix wp su26 plugin list --status=active
./matrix wp su26 plugin list --status=inactive

# Install plugins
./matrix wp su26 plugin install woocommerce --activate
./matrix wp su26 plugin install wordpress-seo --activate
./matrix wp su26 plugin install query-monitor --activate

# Deactivate / Delete
./matrix wp su26 plugin deactivate woocommerce
./matrix wp su26 plugin delete woocommerce

# List themes
./matrix wp su26 theme list

# Install theme
./matrix wp su26 theme install twentytwentysix --activate
```

### Database Operations

```bash
# Search and replace (useful for migrating URLs)
./matrix wp su26 search-replace "http://old-url.com" "http://localhost:8202" --skip-plugins --skip-themes

# Export database
./matrix wp su26 db export backup.sql

# Import database
./matrix wp su26 db import backup.sql

# Reset database (DANGEROUS — deletes all data)
./matrix wp su26 db reset --yes
```

### Cache Management

```bash
# Flush object cache
./matrix wp su26 cache flush

# Flush super cache
./matrix wp su26 super-cache flush
```

### Post & Page Operations

```bash
# Create a new post
./matrix wp su26 post create --post_title="Hello World" --post_content="Content here" --post_status=publish

# List posts
./matrix wp su26 post list --post_type=post --post_status=publish

# Update post
./matrix wp su26 post update 1 --post_title="New Title"

# Delete post
./matrix wp su26 post delete 1 --force
```

### User Management

```bash
# List users
./matrix wp su26 user list

# Create admin user
./matrix wp su26 user create john john@example.com --role=administrator --user_pass=password

# Reset user password
./matrix wp su26 user update admin --user_pass=newpassword
```

### Utility Commands

```bash
# Evaluate PHP code
./matrix wp su26 eval 'echo get_bloginfo("url");'

# Run WP-CLI in an interactive shell (type commands directly)
docker exec -it wp_cli wp --path="/var/www/html/wp_su26" shell

# Get raw DB access
docker exec -it wp_db mysql -u root -p${MYSQL_ROOT_PASSWORD} su26_db
```

---

## PHPStan

PHPStan performs static analysis on PHP code to catch bugs and type errors.

### Basic Usage

```bash
# Run PHPStan on a specific site
./matrix check <site-name>

# Run on a specific path
./matrix check <site-name> <path>

# Examples
./matrix check su26
./matrix check su26 wp-content/plugins/my-plugin/
./matrix check su26 wp-content/themes/my-theme/
```

### What It Checks

- Type errors and incorrect function usage
- Undefined variables, functions, classes
- Incorrect parameter/return types
- WordPress-specific coding standards

### PHPStan Configuration

The project is configured for **Level 9** (strictest). Configuration is in `phpstan.neon`:

- Level 9: maximum strictness
- WordPress globals are in the ignores list
- Excludes vendor, node_modules, and cache directories

### Running Manually

```bash
# Run PHPStan directly via Docker
docker run --rm -v "$(pwd)":/project -w /project \
  ghcr.io/phpstan/phpstan:latest analyse \
  wp_su26/wp-content/plugins/my-plugin/ \
  --level=9

# Run with a specific config file
docker run --rm -v "$(pwd)":/project -w /project \
  ghcr.io/phpstan/phpstan:latest analyse \
  --configuration=phpstan.neon \
  wp_su26/
```

---

## PHP CodeSniffer (PHPCS)

PHPCS checks PHP code against coding standards (WordPress Coding Standards).

### Basic Usage

```bash
# Run on a site
docker run --rm -v "$(pwd)":/workspace -w /workspace \
  wpengine/phpcs:latest \
  wp_su26/wp-content/themes/my-theme/

# Run with specific standard
docker run --rm -v "$(pwd)":/workspace -w /workspace \
  wpengine/phpcs:latest \
  --standard=WordPress \
  wp_su26/wp-content/themes/my-theme/

# Run with WordPress Coding Standards ruleset
docker run --rm -v "$(pwd)":/workspace -w /workspace \
  wpengine/phpcs:latest \
  --standard=WordPress-Core \
  wp_su26/wp-content/plugins/my-plugin/
```

---

## Shell Access

Access interactive shells inside running containers.

```bash
# Access WordPress container shell
./matrix shell wp

# Access database shell (MySQL)
./matrix shell db

# Access nginx shell
./matrix shell nginx
```

The `wp` shell drops you into the first running WordPress container. The `db` shell connects as root to MySQL. The `nginx` shell accesses the first running nginx container.

---

## Site Info & URLs

```bash
# Show detailed site information (status, port, PHP version, disk usage, DB size)
./matrix info <site-name>

# Machine-readable JSON output
./matrix info <site-name> --json

# Show site URLs
./matrix url <site-name>

# Show WordPress REST API metadata
./matrix rest <site-name>
```

---

## XDebug

Configure XDebug for step debugging in VS Code or PHPStorm.

```bash
# Enable XDebug for a site
./matrix xdebug <site-name>
```

This writes XDebug settings to `.user.ini` in the site directory:
- `xdebug.mode = develop,debug`
- `xdebug.client_host = host.docker.internal`
- `xdebug.start_with_request = yes`
- `xdebug.idekey = "VSCODE"`

**VS Code setup:**
1. Install the "PHP Debug" extension
2. Add to `.vscode/launch.json`:
   ```json
   {
     "name": "Listen for Xdebug",
     "type": "php",
     "request": "launch",
     "pathMappings": { "/var/www/html": "${workspaceFolder}" },
     "port": 9003
   }
   ```

**PHPStorm setup:**
1. Settings > PHP > Servers: add mapping `/var/www/html` -> site directory
2. Use the browser extension or append `?XDEBUG_SESSION_START` to URL

---

## Scaffold

Generate starter themes, plugins, or child themes.

```bash
# Create a new theme
./matrix scaffold theme <name>

# Create a new plugin
./matrix scaffold plugin <name>

# Create a child theme
./matrix scaffold child <name>
```

Files are created in `wp_content/themes/` or `wp_content/plugins/`. Each scaffold includes a basic file structure with style.css, index.php (for themes), and a main plugin file.

---

## Site Presets

Pre-configured site templates for common WordPress stacks.

```bash
# List available presets
./matrix preset

# Create a site with a preset
./matrix create <site-name> --preset=<preset>
```

| Preset | Description |
|--------|-------------|
| `blank` | Empty WordPress installation (default) |
| `woocommerce` | WooCommerce with starter theme |
| `elementor` | Elementor page builder |
| `bbpress` | bbPress forum plugin |
| `buddypress` | BuddyPress social network |
| `multisite` | WordPress Multisite |

---

## File Watcher

Watches a site's files for changes and automatically clears OPcache.

```bash
# Watch a site for changes
./matrix watch <site-name>
```

Uses `fswatch` if available (recommended), otherwise falls back to polling mode. Clears OPcache whenever PHP files change, so you see edits immediately without manual refresh.

---

## Optimize

Apply performance optimizations to a site.

```bash
# Optimize a specific site
./matrix optimize <site-name>

# Optimize all sites
./matrix optimize
```

Copies optimization files (object cache drop-in, performance mu-plugin) and applies runtime tweaks when the container is running.

---

## Email Testing (Mailpit)

Mailpit captures outgoing emails for testing without sending to real addresses.

```bash
# Check Mailpit status
./matrix status  # Shows Mailpit in the services list

# Access Mailpit UI
open http://localhost:8025
```

Mailpit runs on port `8025` (web UI) and `1025` (SMTP). WordPress emails sent via `wp_mail()` are captured and viewable in the web interface.

---

## Database Import/Export

```bash
# Export a site's database
./matrix export-db <site-name>

# Import a database file into a site
./matrix import-db <site-name> <backup-file.sql>
```

---

## Utility Scripts

Standalone scripts in `scripts/` for common operations.

### Health Check

```bash
# Run full system health check
scripts/health-check.sh
```

Checks container status, database connectivity, Redis, port availability, and recent logs.

### Search & Replace

```bash
# Database URL migration
./matrix search-replace <site-name> <old-url> <new-url>
```

Or use the script directly:
```bash
scripts/search-replace.sh <site-name> <old-url> <new-url>
```

### Clone Site

```bash
# Clone an existing site
./matrix clone <source-site> <new-site>
```

Or use the script:
```bash
scripts/clone.sh <source-site> <new-site>
```

### Reset Site

```bash
# Reset a site to fresh install (DELETES all data)
./matrix reset <site-name>

# Or use the script
scripts/reset.sh <site-name>
```

### Update WordPress Core

```bash
# Update WordPress core for all sites
./matrix update

# Or use the script
scripts/update-core.sh
```

### Clear Caches

```bash
# Clear all caches (object cache, OPcache, super cache)
./matrix cache

# Or use the script
scripts/cache-clear.sh
```

---

## Frontend Dashboard

A web-based management interface running on port `8500`.

```bash
# Start the frontend
./matrix frontend start

# Stop the frontend
./matrix frontend stop

# Restart the frontend
./matrix frontend restart

# Check frontend status
./matrix frontend status
```

Access at `http://localhost:8500`. Provides a UI for creating, starting, stopping sites and running code quality checks.

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `./matrix wp <site> <cmd>` | Run WP-CLI command |
| `./matrix check <site> [path]` | Run PHPStan/PHPCS |
| `./matrix shell <type>` | Access container shell (wp/db/nginx) |
| `./matrix info <site>` | Site details |
| `./matrix url <site>` | Site URLs |
| `./matrix rest <site>` | REST API metadata |
| `./matrix xdebug <site>` | Configure XDebug |
| `./matrix scaffold <type> <name>` | Create theme/plugin/child |
| `./matrix preset` | List site presets |
| `./matrix watch <site>` | Watch files + clear OPcache |
| `./matrix optimize [site]` | Apply performance tweaks |
| `./matrix export-db <site>` | Export database |
| `./matrix import-db <site> <file>` | Import database |
| `./matrix clone <src> <dst>` | Clone site |
| `./matrix reset <site>` | Reset site (destructive) |
| `./matrix update` | Update WordPress core |
| `./matrix cache` | Clear all caches |
| `./matrix frontend start\|stop\|restart\|status` | Manage web dashboard |
| `scripts/health-check.sh` | System health check |

## Tips

- Use `./matrix wp` instead of running `docker-compose exec` — it handles networking and DB credentials automatically
- Run `./matrix check <site>` before committing to catch issues early
- Use `--json` flag with `./matrix` commands for machine-readable output
- WP-CLI commands can be chained: `./matrix wp su26 plugin install woocommerce --activate && ./matrix wp su26 wc --version`
- Run `./matrix status` to see all running services at a glance
