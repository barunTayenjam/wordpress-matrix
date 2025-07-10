# WordPress Site Management Scripts - Fixes Applied

## Issues Identified and Fixed

### 1. Service Name Mismatch
**Problem**: The original `manage-sites.sh` script was looking for services named `wordpress_<sitename>` and `nginx_<sitename>`, but the actual docker-compose.yml uses fixed service names like `xandar`, `sakaar`, `nginx-wp1`.

**Fix**: Updated the service discovery and management functions to handle both predefined sites (xandar, sakaar) and dynamic sites (wordpress_*) correctly.

### 2. Directory Structure Mismatch
**Problem**: The script expected directories named `wordpress_<sitename>` but the actual structure uses `xandar/` and `sakaar/` directories.

**Fix**: Added logic to detect both predefined site directories and dynamic site directories.

### 3. Environment Variable Loading
**Problem**: Scripts weren't loading environment variables from `.env` file, causing issues with database connections and domain configuration.

**Fix**: Added environment variable loading to both `manage-sites.sh` and `manage.sh` scripts.

### 4. Health Check Issues
**Problem**: The `manage.sh` script had hardcoded health check services that didn't match the actual docker-compose structure.

**Fix**: 
- Updated health check services list
- Improved health check logic to handle services without health checks
- Added fallback to check if service is running when health check is not available

### 5. Path Resolution Issues
**Problem**: The `manage.sh` script had hardcoded relative paths that didn't work when called from different directories.

**Fix**: Updated all script references to use absolute paths based on `SCRIPT_DIR`.

## Key Improvements Made

### Enhanced Site Discovery
- Detects both predefined sites (xandar, sakaar) and dynamic sites (wordpress_*)
- Properly handles different directory structures
- Correctly maps service names for different site types

### Better Error Handling
- Prevents removal of predefined sites
- Provides helpful error messages with available options
- Validates site existence before operations

### Improved Service Management
- Correctly starts/stops appropriate services for each site type
- Handles shared nginx container for predefined sites
- Supports both individual and bulk operations

### Environment Integration
- Loads environment variables from `.env` file
- Uses configured domain suffix for URLs
- Properly references database names and credentials

## Commands Now Working

### manage-sites.sh
```bash
./scripts/manage-sites.sh list                 # List all sites
./scripts/manage-sites.sh start <site-name>    # Start a site
./scripts/manage-sites.sh stop <site-name>     # Stop a site
./scripts/manage-sites.sh restart <site-name>  # Restart a site
./scripts/manage-sites.sh info <site-name>     # Show site info
./scripts/manage-sites.sh remove <site-name>   # Remove dynamic sites only
./scripts/manage-sites.sh help                 # Show help
```

### manage.sh (updated commands)
```bash
./scripts/manage.sh list-sites                 # List all sites
./scripts/manage.sh site-info <site-name>      # Show site info
./scripts/manage.sh start                      # Start environment
./scripts/manage.sh stop                       # Stop environment
./scripts/manage.sh status                     # Show status
```

## Site Types Supported

### Predefined Sites
- **xandar**: Uses `xandar/` directory, `xandar` service, shared nginx
- **sakaar**: Uses `sakaar/` directory, `sakaar` service, shared nginx
- Cannot be removed (only stopped)
- Use predefined database names from environment

### Dynamic Sites
- Use `wordpress_<name>/` directory structure
- Use `wordpress_<name>` and `nginx_<name>` services
- Can be created and removed
- Use `<name>_db` database naming

## Testing Results

All commands tested and working:
- ✅ Site listing and discovery
- ✅ Site information display
- ✅ Service start/stop operations
- ✅ Error handling and validation
- ✅ Environment variable loading
- ✅ Path resolution
- ✅ Health checks and status monitoring

The scripts now properly integrate with the existing WordPress development environment and provide reliable site management capabilities.