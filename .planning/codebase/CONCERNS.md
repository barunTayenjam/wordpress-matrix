# Concerns - WordPress Matrix Development Platform

## Critical Issues

### 1. Mutable docker-compose.yml

**Severity: High** | `docker-compose.yml`

The `create_site()` function at `matrix:266-321` and `remove_site()` at `matrix:556-575` directly modify `docker-compose.yml` using `awk` and temporary files. This approach:

- Is fragile — depends on exact YAML formatting and comment patterns
- Has no backup before modification
- Can corrupt the file if the process is interrupted mid-write
- Makes version control messy (the file is tracked but constantly changes)
- The removal logic at `matrix:560-564` depends on comment patterns like `# WordPress site: <name>` which could break if comments are reformatted

**Risk**: File corruption leading to all services being misconfigured.

### 2. No Input Sanitization for Database Operations

**Severity: High** | `matrix`, `scripts/*.sh`

Site names are used directly in SQL queries without proper escaping:
- `matrix:326`: `"CREATE DATABASE IF NOT EXISTS ${site_name}_db;"`
- `scripts/backup.sh:77`: `mysqldump ... "${SOURCE_SITE}_db"`
- `scripts/reset.sh:89`: `"DROP DATABASE IF EXISTS $DB_NAME"`

While the `create_site()` function validates site names with alphanumeric rules (`matrix:193`), other entry points may not be as strict. SQL injection is possible if site name validation is bypassed.

### 3. Duplicated Code Between matrix and scripts/common.sh

**Severity: Medium** | `matrix:1-43`, `scripts/common.sh`

Both files contain identical implementations of:
- Logging functions (`log_info`, `log_success`, `log_warning`, `log_error`)
- Color definitions (`RED`, `GREEN`, `YELLOW`, `BLUE`, `NC`)
- Docker compose detection
- `get_sites()`, `site_exists()`, `get_next_port()`

The `matrix` script does NOT source `common.sh` — it has its own copies. This means bug fixes must be applied in two places.

### 4. Frontend Has No Authentication

**Severity: Medium** | `frontend/app.js`

The Express server at port 8500 has no authentication or authorization:
- Anyone who can reach port 8500 can create/delete WordPress sites
- The terminal tab allows executing arbitrary `matrix` commands
- No rate limiting on API endpoints

**Mitigation**: Only runs on localhost, but if exposed to a network, this is a critical vulnerability.

### 5. Unused Dependencies

**Severity: Low** | `frontend/package.json`

- `axios` (^1.6.0): Declared in dependencies but never imported or used in `frontend/app.js` or any other file
- `socket.io` (^4.7.4): Declared in dependencies but never used
- These increase install size and attack surface unnecessarily

## Technical Debt

### 6. No Error Recovery for Site Creation

**Severity: Medium** | `matrix:157-337`

`create_site()` performs multiple steps (directory creation, WordPress file copy, nginx config, compose file edit, database creation, container start) but has no rollback on failure. If the compose file edit succeeds but database creation fails, the system is left in an inconsistent state.

### 7. Text Parsing for State Discovery

**Severity: Medium** | `frontend/app.js:81-123`

The frontend `parseSiteList()` function parses human-readable CLI output text to extract structured data. This is fragile:
- Depends on exact column widths and formatting
- Breaks if the `list_sites()` output format changes
- The regex `parts = line.trim().split(/\s{2,}/)` assumes specific whitespace patterns

### 8. Hardcoded Port Numbers

**Severity: Low** | Multiple files

- `frontend/app.js:10`: `PORT = process.env.PORT || 3000` but started with `PORT=8500`
- `frontend/healthcheck.js:5`: `port: 8500` hardcoded
- `frontend/Dockerfile:26`: `EXPOSE 8000` but actually runs on 8500
- `matrix:1228`: `PORT=8500 npm start` hardcoded in manage_frontend
- `scripts/common.sh:68`: `local max_port=8100` hardcoded start port

### 9. docker-compose.yml Version Discrepancy

**Severity: Low** | `docker-compose.yml`, `matrix:998`

The current `docker-compose.yml` has no `version:` key, but the generated compose in `install_env()` at `matrix:998` uses `version: '3.8'`. This inconsistency could cause issues with different Docker Compose versions.

### 10. `fix` Command Not Implemented

**Severity: Low** | `matrix:1409`

The `fix` command is listed in help but simply prints "Auto-fix not implemented yet".

### 11. `wp-cli` Volume Mount Mismatch

**Severity: Medium** | `docker-compose.yml:83`

The WP-CLI container has `volumes: - ./wp_:/var/www/html:rw` — this mounts a literal `wp_` directory (not a glob pattern). This means WP-CLI only works if there's a directory exactly named `wp_`, which won't match actual site directories like `wp_asgard`.

Scripts that use WP-CLI (`scripts/search-replace.sh:58`, `scripts/update-core.sh:66`) reference paths like `/var/www/html/$SITE_NAME` which won't resolve correctly with this volume mount.

## Performance Concerns

### 12. Frontend Spawn Overhead

**Severity: Low** | `frontend/app.js:30-78`

Every API request spawns a new `matrix` process via `child_process.spawn()`. For the dashboard view, this means a fresh process invocation for every page load. No caching or persistent connection to the CLI.

### 13. Code Quality Check Duration

**Severity: Low** | `matrix:730-811`

Running `./matrix check` on all sites pulls Docker images and scans all theme/plugin code. AGENTS.md notes this can take 2+ minutes. PHPStan is intentionally skipped for full-site scans due to timeout concerns.

## Security Concerns

### 14. Database Credentials in Process Arguments

**Severity: Medium** | `scripts/*.sh`

MySQL credentials are passed as command-line arguments to `docker exec` calls (e.g., `scripts/backup.sh:77`: `-p"${MYSQL_PASSWORD}"`). These may be visible in `ps` output on the host system.

### 15. No .env Validation

**Severity: Low** | `matrix:28-32`, `scripts/common.sh:25-29`

Both load `.env` files unconditionally with `set -a; source .env; set +a`. No validation that required variables exist. If `.env` is missing or incomplete, errors surface deep in execution rather than at startup.

### 16. SSL Directory Empty

**Severity: Low** | `ssl-certs/`

The `ssl-certs/` directory exists but is empty. AGENTS.md references SSL support but no SSL termination is configured. All sites run on HTTP only.

## Fragile Areas

### 17. Site Removal Depends on Comment Pattern

**Severity: Medium** | `matrix:560-564`

The `remove_site()` function identifies service blocks in `docker-compose.yml` by matching the comment `# WordPress site: <name>`. If the comment format changes or is removed, site removal will fail silently (leaving orphaned service definitions).

### 18. Port Collision Risk

**Severity: Low** | `matrix:137-154`, `scripts/common.sh:67-81`

`get_next_port()` finds the highest port in `docker-compose.yml` and increments. But it also checks with `ss -tln` if the port is in use. There's a race condition between checking and actually binding the port. Also, the initial value of 8100 conflicts with the actual ports being assigned starting at 8200+.

### 19. `setup_env()` Creates Wrong Filename

**Severity: Low** | `matrix:907`

`setup_env()` checks for `"$PROJECT_ROOT/$DOCKER_COMPOSE.yml"` which expands to something like `"$PROJECT_ROOT/docker-compose.yml"` (correct) but only because `$DOCKER_COMPOSE` is set to `docker-compose`. This is confusing and fragile if the variable ever changes.
