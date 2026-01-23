# WordPress Development Platform Maintenance Scripts

This directory contains utility scripts for common maintenance tasks.

## Available Scripts

### Backup & Restore
- `backup.sh` - Backup all sites (database + files)
- `restore.sh` - Restore site from backup
- `backup-db.sh` - Automated daily database backups

### Site Management
- `clone.sh` - Clone existing WordPress site
- `reset.sh` - Reset site (fresh WordPress install)
- `duplicate.sh` - Duplicate site with search/replace
- `archive.sh` - Archive site (compress and remove)

### WordPress Core
- `update-core.sh` - Update WordPress core for all sites
- `update-plugins.sh` - Update all plugins
- `update-themes.sh` - Update all themes
- `upgrade-all.sh` - Update everything (core, plugins, themes)

### Development Tools
- `wp-cli-shortcuts.sh` - Common WP-CLI commands shortcuts
- `search-replace.sh` - Search and replace across database
- `cache-clear.sh` - Clear all caches (Redis, WordPress)
- `log-rotate.sh` - Rotate and compress logs

### Database Tools
- `db-optimize.sh` - Optimize all databases
- `db-repair.sh` - Repair WordPress tables
- `db-stats.sh` - Show database sizes and stats

### Git Integration
- `git-init.sh` - Initialize git for WordPress sites
- `git-sync.sh` - Sync site files to remote
- `git-hooks.sh` - Install git hooks for WordPress

### Quality Tools
- `security-scan.sh` - Run security audit
- `performance-test.sh` - Test site performance
- `link-check.sh` - Check for broken links

### System Tools
- `health-check.sh` - Check all system health
- `cleanup.sh` - Clean unused resources
- `diagnostics.sh` - Generate diagnostics report
- `migrate.sh` - Migrate site to production

## Usage Examples

```bash
# Backup all sites
./scripts/backup.sh --all

# Clone a site
./scripts/clone.sh source-site new-site

# Reset a site to fresh install
./scripts/reset.sh mysite

# Update WordPress core everywhere
./scripts/update-core.sh --all

# Search and replace URLs
./scripts/search-replace.sh mysite "http://dev.local" "https://production.com"

# Create daily backups
./scripts/backup-db.sh --schedule=daily --keep=7

# Clear all caches
./scripts/cache-clear.sh --all

# System health check
./scripts/health-check.sh
```

## Integration with Matrix

These scripts can be called from the main `matrix` script:

```bash
./matrix backup [site]
./matrix clone <source> <target>
./matrix reset <site>
./matrix update <site> --all
./matrix cache-clear <site>
./matrix health
```

## Scheduling

Use cron for automated tasks:

```bash
# Daily backups at 2 AM
0 2 * * * /path/to/matrix/scripts/backup-db.sh --all

# Weekly cleanup on Sundays
0 3 * * 0 /path/to/matrix/scripts/cleanup.sh

# Monthly updates
0 4 1 * * /path/to/matrix/scripts/upgrade-all.sh --all
```
