# Testing - WordPress Matrix Development Platform

## Current State

**There are no automated tests in this project.**

### Frontend

The `frontend/package.json` test script is a placeholder:

```json
"test": "echo \"Error: no test specified\" && exit 1"
```

No test frameworks are installed (no jest, mocha, chai, etc. in dependencies or devDependencies).

### Bash Scripts

No test framework for the `matrix` CLI or utility scripts. No bats (Bash Automated Testing System), no shunit2, no shellcheck integration.

### PHP Quality Tools

PHP CodeSniffer and PHPStan are configured for **analyzing WordPress site code** (the contents of `wp_*/wp-content/`), not the platform code itself. These run inside Docker containers against WordPress themes and plugins.

- **PHPCS**: `--standard=WordPress` against custom themes/plugins
- **PHPStan**: Level 5 against specific paths only
- Both use `--profile tools` (on-demand, not part of CI)

## What Could Be Tested

### CLI (`matrix`)

| Function | Testable Behavior |
|----------|-------------------|
| `get_sites()` | Returns list of wp_* directories |
| `site_exists()` | Checks directory existence |
| `get_next_port()` | Calculates next available port from compose file |
| `create_site()` | Creates directory, nginx config, compose entries, database |
| `remove_site()` | Removes containers, files, database, compose entries |
| `edit_site()` | Updates PHP version and port in compose file |
| `parseSiteList()` (frontend) | Parses CLI text output into structured data |

### Frontend API

| Endpoint | Expected Behavior |
|----------|-------------------|
| `GET /api/sites` | Returns JSON with sites and services |
| `POST /api/sites/create` | Creates new site via matrix CLI |
| `POST /api/sites/start` | Starts site via matrix CLI |
| `GET /health` | Returns `{ status: 'healthy' }` |

### Utility Scripts

| Script | Testable Behavior |
|--------|-------------------|
| `scripts/backup.sh` | Creates backup directory, dumps database, copies files |
| `scripts/clone.sh` | Clones files, updates config, creates database |
| `scripts/reset.sh` | Backs up, drops/recreates database, optionally restores content |
| `scripts/cache-clear.sh` | Flushes Redis, runs WP cache flush |
| `scripts/health-check.sh` | Reports status of all components |

## Suggested Testing Approach

### Bash Testing

- **ShellCheck** for static analysis of all `.sh` files
- **bats-core** for integration testing of `matrix` commands against a test Docker environment
- Test fixtures: mock `wp_*/` directories and `docker-compose.yml`

### Frontend Testing

- **Jest** for unit tests of `parseSiteList()` and route handlers
- **Supertest** for HTTP endpoint testing against Express app
- Mock `child_process.spawn` to avoid needing real Docker during tests

### PHP Testing

- PHPUnit for WordPress theme/plugin code (if custom code exists in sites)
- Tests would run inside Docker containers against actual WordPress installations

## CI/CD

**No CI/CD pipeline exists.** No GitHub Actions, GitLab CI, or other automation.

### Potential CI Pipeline

1. **Lint**: ShellCheck on `matrix` and `scripts/*.sh`
2. **Unit tests**: Jest for frontend, bats for CLI
3. **Integration**: Docker-based tests for site creation/removal
4. **Code quality**: PHPCS/PHPStan against sample WordPress code

## Test Commands (Current)

| Command | What it does |
|---------|-------------|
| `cd frontend && npm test` | Exits with error "no test specified" |
| `./matrix check` | Runs PHPCS/PHPStan on WordPress site code (not platform code) |
| `./matrix test` | Alias for `./matrix check` |
