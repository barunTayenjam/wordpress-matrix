# Synthesized Requirements

No PRDs found in this ingest set. The following requirements are extracted from SPEC-type documents (FLOW_REVIEW.md, IMPROVEMENT_PLAN.md) as derived requirements for a new Bash-hardening/shell-testing workstream.

## REQ-password-exposure
- **Source**: FLOW_REVIEW.md (#10)
- **Description**: Replace inline `-p"$PASSWORD"` CLI args with `-e MYSQL_PWD="$PASSWORD"` across all database call sites to prevent password exposure in process listings.
- **Scope**: matrix, scripts/common.sh, scripts/backup.sh, scripts/reset.sh, scripts/clone.sh — 11 call sites
- **Acceptance**: No MySQL/mysqldump invocation passes password as CLI argument; all use MYSQL_PWD env var or defaults-extra-file

## REQ-env-permissions
- **Source**: FLOW_REVIEW.md (#11)
- **Description**: Harden `.env` file permissions with `chmod 600` after every write.
- **Scope**: matrix (setup_env, repair_env)
- **Acceptance**: .env created with 600 permissions; no world-readable credentials

## REQ-gitignore-env
- **Source**: FLOW_REVIEW.md (#14)
- **Description**: Verify `.gitignore` covers `.env` and `wp_*/.env`; add pre-commit guard against credential leakage.
- **Scope**: .gitignore, pre-commit hook
- **Acceptance**: .gitignore includes .env patterns; commit containing MYSQL_PASSWORD is rejected

## REQ-random-passwords
- **Source**: FLOW_REVIEW.md (#4)
- **Description**: Replace hardcoded default passwords in setup_env/repair_env with `openssl rand -base64 16` generation.
- **Scope**: matrix (setup_env, repair_env), .env.example
- **Acceptance**: Fresh .env created with random credentials; .env.example updated to match

## REQ-die-error-handling
- **Source**: FLOW_REVIEW.md (#5)
- **Description**: Adopt consistent die() error protocol across all shell scripts.
- **Scope**: scripts/helpers.sh, matrix, scripts/*.sh
- **Acceptance**: die() defined that exits 1 with message; `exit 1` and `return 1` calls audited and replaced where appropriate

## REQ-test-check-alias
- **Source**: FLOW_REVIEW.md (#6)
- **Description**: Remove the `test` alias from matrix dispatch or route it to a real test runner.
- **Scope**: matrix
- **Acceptance**: `./matrix test` either removed or runs PHPUnit/Jest instead of PHPCS/PHPStan

## REQ-health-json
- **Source**: FLOW_REVIEW.md (#5)
- **Description**: Add `--json` support to health-check.sh for machine-parseable output.
- **Scope**: scripts/health-check.sh, matrix
- **Acceptance**: `matrix health --json` emits structured JSON matching status/info format

## REQ-shared-bootstrap
- **Source**: FLOW_REVIEW.md (#8)
- **Description**: Extract duplicated bootstrap code (~40 lines) from matrix and common.sh into a shared library.
- **Scope**: matrix, scripts/common.sh, lib/bootstrap.sh (new)
- **Acceptance**: Both matrix and common.sh source the same bootstrap file; no duplicated docker-compose detection, color/logger defs, or .env loading

## REQ-domain-modules
- **Source**: FLOW_REVIEW.md (#9)
- **Description**: Split monolithic matrix into domain-specific sourced modules.
- **Scope**: matrix, lib/site.sh (new), lib/env.sh (new), lib/db.sh (new), lib/devtools.sh (new)
- **Acceptance**: Functions moved domain-by-domain; matrix sources all modules; all commands work identically

## REQ-compose-abstraction
- **Source**: FLOW_REVIEW.md (#11)
- **Description**: Formalize the Docker/Compose abstraction — always use Compose for up/down and docker exec for runtime ops.
- **Scope**: matrix, scripts/compose-lib.sh
- **Acceptance**: No raw `docker start/stop` fallback paths; documented contract

## REQ-dispatch-array
- **Source**: FLOW_REVIEW.md (#12)
- **Description**: Replace flat `case "$command"` dispatch with an associative array mapping command to function.
- **Scope**: matrix
- **Acceptance**: declare -A COMMANDS map; --help derived from map keys; `matrix help <cmd>` enabled

## REQ-per-site-credentials
- **Source**: FLOW_REVIEW.md (#12)
- **Description**: Generate unique database credentials per site at creation time; store in site-local .env.
- **Scope**: matrix, wp_<site>/.env, all DB call sites
- **Acceptance**: Each site has unique MYSQL_USER/MYSQL_PASSWORD; global .env holds only infrastructure secrets

## REQ-rotate-secrets
- **Source**: FLOW_REVIEW.md (#13)
- **Description**: Add `matrix rotate-secrets` command to regenerate site passwords, run ALTER USER, update wp-config.php.
- **Scope**: matrix (new command), scripts/*.sh
- **Acceptance**: One command re-keys all site credentials atomically

## REQ-shell-tests
- **Source**: FLOW_REVIEW.md (#14)
- **Description**: Add shell script test coverage with bats for critical paths.
- **Scope**: tests/ directory, scripts/*.sh
- **Acceptance**: bats tests for site creation/removal, port allocation, validation functions, DB import/export

## Derived from IMPROVEMENT_PLAN.md (scope: future workstream)

### REQ-site-search-filter
- **Source**: IMPROVEMENT_PLAN.md (1.1)
- **Description**: Add search bar and filters to sites list in dashboard.
- **Acceptance**: Filter by name, status (running/stopped), PHP version; sort by name/date/status

### REQ-scheduled-backups
- **Source**: IMPROVEMENT_PLAN.md (1.2)
- **Description**: Cron-based automatic backups with configurable retention.
- **Acceptance**: Backup scheduled; N most recent backups retained; timestamped files

### REQ-container-resource-limits
- **Source**: IMPROVEMENT_PLAN.md (1.3)
- **Description**: Memory and CPU limits per site container.
- **Acceptance**: Limits configured in docker-compose.yml per service

### REQ-activity-log
- **Source**: IMPROVEMENT_PLAN.md (1.4)
- **Description**: Log all site operations; show in dashboard; filterable.
- **Acceptance**: Operations logged; dashboard viewable; filtered by action type

### REQ-ssl-tls
- **Source**: IMPROVEMENT_PLAN.md (2.1)
- **Description**: Add SSL/TLS support with self-signed certs or mkcert.
- **Acceptance**: Per-site certs generated; HTTPS available in local dev

### REQ-dashboard-auth
- **Source**: IMPROVEMENT_PLAN.md (2.2)
- **Description**: Basic auth for the web dashboard.
- **Acceptance**: Auth gate on dashboard; session management

### REQ-backup-encryption
- **Source**: IMPROVEMENT_PLAN.md (2.3)
- **Description**: Optional GPG encryption for backups.
- **Acceptance**: Password-protected backup archives

### REQ-git-deployment
- **Source**: IMPROVEMENT_PLAN.md (3.1)
- **Description**: Git repository connection with auto-deploy on push.
- **Acceptance**: Branch selection (dev/staging/prod); webhook-triggered deploy

### REQ-hot-reload
- **Source**: IMPROVEMENT_PLAN.md (3.2)
- **Description**: Watch theme/plugin files for changes; auto-sync.
- **Acceptance**: mutagen for macOS; livereload in browser

### REQ-wpcli-enhanced-ui
- **Source**: IMPROVEMENT_PLAN.md (3.3)
- **Description**: WP-CLI plugin/theme/core management UI.
- **Acceptance**: Plugin install/update, theme management, core updates from dashboard

### REQ-multisite
- **Source**: IMPROVEMENT_PLAN.md (4.1)
- **Description**: WordPress multisite network support.
- **Acceptance**: Multisite creation; network admin UI

### REQ-orchestration
- **Source**: IMPROVEMENT_PLAN.md (4.2)
- **Description**: Traefik integration for routing; automatic SSL with Let's Encrypt.
- **Acceptance**: Domain management; auto-SSL; routing via Traefik

### REQ-monitoring-dashboard
- **Source**: IMPROVEMENT_PLAN.md (4.3)
- **Description**: Resource usage graphs, response time tracking, uptime monitoring.
- **Acceptance**: Charts for CPU/memory; response time history; uptime percentage
