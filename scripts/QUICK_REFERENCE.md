# Quick Reference: New Maintenance Scripts

## Scripts Created

All scripts are in the `scripts/` directory and can be run directly or integrated with the `matrix` command.

### 1. **clone.sh** - Clone existing site
```bash
./scripts/clone.sh <source-site> <new-site>
# Example: ./scripts/clone.sh mysite mysite-copy
```
**What it does:**
- Copies all files
- Creates new database
- Imports database
- Updates URLs via search/replace
- Updates docker-compose.yml

---

### 2. **reset.sh** - Reset site to fresh install
```bash
./scripts/reset.sh <site-name> [--keep-plugins] [--keep-themes] [--keep-uploads]
# Example: ./scripts/reset.sh mysite --keep-plugins
```
**What it does:**
- Creates backup first
- Drops and recreates database
- Optionally preserves plugins/themes/uploads
- Leaves backup in `backups/` directory

---

### 3. **update-core.sh** - Update WordPress core
```bash
./scripts/update-core.sh [site-name] [--all] [--force]
# Examples:
./scripts/update-core.sh mysite
./scripts/update-core.sh --all --force
```
**What it does:**
- Updates WordPress core
- Updates database
- Can update all sites at once
- Force update even if already latest

---

### 4. **cache-clear.sh** - Clear all caches
```bash
./scripts/cache-clear.sh [site-name] [--all] [--redis-only] [--wp-only]
# Examples:
./scripts/cache-clear.sh mysite
./scripts/cache-clear.sh --all
./scripts/cache-clear.sh mysite --redis-only
```
**What it does:**
- Flushes Redis cache
- Flushes WordPress object cache
- Can target specific caches

---

### 5. **search-replace.sh** - Database search/replace
```bash
./scripts/search-replace.sh <site-name> <search> <replace> [--dry-run] [--precise]
# Examples:
./scripts/search-replace.sh mysite "http://dev.local" "https://production.com"
./scripts/search-replace.sh mysite "old-domain" "new-domain" --dry-run
```
**What it does:**
- Search and replace in database
- Dry-run mode to preview changes
- Precise mode for exact matches

---

### 6. **backup.sh** - Backup sites
```bash
./scripts/backup.sh [site-name] [--all] [--db-only] [--files-only] [--compress]
# Examples:
./scripts/backup.sh mysite
./scripts/backup.sh --all --compress
./scripts/backup.sh mysite --db-only
```
**What it does:**
- Backup database + files
- Timestamped backup directory
- Can compress backups
- Can backup all sites at once

---

### 7. **health-check.sh** - System health check
```bash
./scripts/health-check.sh
```
**What it does:**
- Checks Docker/Podman
- Checks container status
- Tests database connection
- Tests Redis connection
- Checks WordPress sites
- Shows disk/memory usage
- Checks for errors in logs
- Detects port conflicts

---

### 8. **common.sh** - Shared functions
Used by all scripts. Contains:
- Logging functions
- Site discovery
- Port management
- Database operations
- Docker compose detection

---

## Integration with Matrix

To integrate these scripts into the main `matrix` command, add these cases to the dispatcher:

```bash
# Add to matrix script main() case statement

"clone")
    shift
    ./scripts/clone.sh "$@"
    ;;
"reset")
    shift
    ./scripts/reset.sh "$@"
    ;;
"update-core"|"update")
    shift
    ./scripts/update-core.sh "$@"
    ;;
"cache-clear")
    shift
    ./scripts/cache-clear.sh "$@"
    ;;
"search-replace")
    shift
    ./scripts/search-replace.sh "$@"
    ;;
"backup")
    shift
    ./scripts/backup.sh "$@"
    ;;
"health")
    ./scripts/health-check.sh
    ;;
```

Then use them like:
```bash
./matrix clone mysite mysite-copy
./matrix reset mysite --keep-plugins
./matrix update --all
./matrix cache-clear --all
./matrix backup --all --compress
./matrix health
```

---

## Common Workflows

### Quick Site Reset
```bash
./matrix reset mysite --keep-plugins --keep-themes
```

### Development to Production Migration
```bash
# 1. Backup first
./matrix backup mysite --compress

# 2. Search and replace URLs
./matrix search-replace mysite "http://localhost:8100" "https://production.com"

# 3. Clear caches
./matrix cache-clear mysite --all
```

### Bulk Update All Sites
```bash
# 1. Update WordPress core
./matrix update --all --force

# 2. Clear all caches
./matrix cache-clear --all

# 3. Check health
./matrix health
```

### Site Cloning for Testing
```bash
# Clone production site to staging
./matrix clone production-site staging-site

# Reset to fresh WordPress but keep plugins
./matrix reset staging-site --keep-plugins --keep-themes

# Clear staging cache
./matrix cache-clear staging-site
```

---

## Backup Strategy

### Daily Automated Backups
```bash
# Add to crontab:
# 0 2 * * * /path/to/matrix/scripts/backup.sh --all --compress
```

### Manual Backup Before Major Changes
```bash
./matrix backup mysite --compress
```

### Selective Backups
```bash
# Database only
./matrix backup mysite --db-only

# Files only (themes, plugins, uploads)
./matrix backup mysite --files-only
```

---

## Troubleshooting

### Site won't start?
```bash
./matrix health
./matrix logs mysite
./matrix cache-clear mysite
```

### Database errors?
```bash
./matrix search-replace mysite --dry-run # Check for old URLs
./matrix reset mysite --keep-uploads # Fresh database
```

### Performance issues?
```bash
./matrix cache-clear --all
./matrix health # Check memory/disk
```

### Port conflicts?
```bash
./matrix health # Shows port status
./matrix list # See assigned ports
```

---

## Notes

- All scripts create backups before destructive operations
- Logs are color-coded for easy reading
- Dry-run mode available for search/replace
- All operations can be run on single site or all sites
- Scripts use shared `common.sh` for consistency
