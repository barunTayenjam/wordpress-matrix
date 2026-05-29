# Requirements - WordPress Matrix Development Platform

## Categories

### Milestone 1 (COMPLETE)
- **API** - Structured JSON API layer
- **WS** - Real-time WebSocket updates
- **TEST** - Testing infrastructure
- **FIX** - Technical debt and code cleanup
- **UI** - Frontend dashboard enhancements

### Milestone 2 (ACTIVE)
- **SEC** - Security hardening
- **INFRA** - Shell infrastructure and tooling
- **ARCH** - Architecture and code organization
- **TEST-SH** - Shell script testing

---

## API - Structured JSON API Layer

### API-01: CLI `--json` flag for structured output

**Priority**: P0 | **Phase**: 1

The `matrix` CLI must support a `--json` flag on key commands (`list`, `status`, `info`, `check`) that outputs machine-parseable JSON to stdout instead of human-readable tables. This replaces the fragile `parseSiteList()` text-splitting approach in `frontend/app.js:81-123`.

**Acceptance criteria**:
- `matrix list --json` outputs `{ sites: [...], services: [...] }` with name, status, port, php_version, container_id per entry
- `matrix status --json` outputs structured service health data
- `matrix info <site> --json` outputs site details (port, PHP version, container status, disk usage)
- `matrix check <site> --json` outputs structured check results (errors, warnings, files scanned)
- Human-readable output remains the default (no `--json` flag)
- JSON output is valid, single-line or pretty-printed, no ANSI color codes

### API-02: Frontend uses `--json` output

**Priority**: P0 | **Phase**: 1

`frontend/app.js` must call `matrix` with `--json` and parse structured JSON instead of splitting text output on whitespace patterns.

**Acceptance criteria**:
- `parseSiteList()` replaced with `JSON.parse()` of CLI output
- All API endpoints (`/api/sites`, `/api/status`, `/api/sites/:action`) use structured data
- Dashboard renders correctly with new data format
- Error responses from CLI are parsed and surfaced properly

### API-03: Structured error responses

**Priority**: P1 | **Phase**: 1

All API endpoints must return consistent, structured error responses with machine-readable error codes.

**Acceptance criteria**:
- Error format: `{ success: false, error: { code: string, message: string, details?: any } }`
- Common error codes: `SITE_NOT_FOUND`, `SITE_ALREADY_EXISTS`, `INVALID_NAME`, `DOCKER_ERROR`, `TIMEOUT`, `COMMAND_FAILED`
- HTTP status codes match error type (400 for validation, 404 for not found, 500 for server errors)
- CLI errors captured from both stdout and stderr

### API-04: Input validation in API layer

**Priority**: P1 | **Phase**: 1

API endpoints must validate inputs before passing them to the CLI.

**Acceptance criteria**:
- Site name validation: alphanumeric + hyphens + underscores, starts with letter, not reserved word
- Action allowlists for `/api/sites/:action` and `/api/environment/:action` (already partially done)
- PHP version validation against supported versions (7.4, 8.0, 8.1, 8.2, 8.3)
- Request body size limits

### API-05: Code quality check API with progress

**Priority**: P2 | **Phase**: 2

Code quality checks are long-running (2+ minutes). The API must support progress reporting.

**Acceptance criteria**:
- `POST /api/sites/check` starts a check and returns a job/check ID
- Check progress pushed via WebSocket (see WS-02)
- Check results available via `GET /api/checks/:id` or pushed on completion
- Concurrent checks don't block other API operations

### API-06: Log streaming endpoint

**Priority**: P2 | **Phase**: 2

Site logs should be streamable to the browser.

**Acceptance criteria**:
- `GET /api/sites/:name/logs?lines=100` returns recent log entries
- Logs streamed via WebSocket for live tailing
- Supports both Docker container logs and nginx access/error logs

---

## WS - Real-time WebSocket Updates

### WS-01: Container status pushed to dashboard

**Priority**: P0 | **Phase**: 2

Dashboard must show real-time container status without page refresh, using socket.io (already a declared dependency).

**Acceptance criteria**:
- socket.io server initialized in `frontend/app.js`
- Client connects on dashboard load
- Container state changes (start, stop, die, create) pushed to connected clients
- Events: `container.started`, `container.stopped`, `container.died`, `status.changed`
- Status polling via Docker events API or periodic `docker ps` (every 5-10 seconds minimum)
- Dashboard updates site status badges in real-time without full page reload

### WS-02: Long-running operation progress

**Priority**: P1 | **Phase**: 2

Operations like `create`, `check`, `start`, `stop` should stream progress to the dashboard.

**Acceptance criteria**:
- `site.creating` event with progress steps (pulling image, copying files, creating DB, starting containers)
- `check.running` event with current file being scanned
- `site.operation` event with final success/failure result
- Progress bar or step indicator in dashboard UI

### WS-03: Log streaming via WebSocket

**Priority**: P2 | **Phase**: 2

Live log tailing delivered to browser via WebSocket.

**Acceptance criteria**:
- `logs.subscribe` event to start streaming logs for a site
- `logs.data` event with log lines as they arrive
- `logs.unsubscribe` event to stop streaming
- Client can subscribe to multiple sites simultaneously

---

## TEST - Testing Infrastructure

### TEST-01: Unit tests for API layer

**Priority**: P1 | **Phase**: 3

The API layer must have unit tests covering all endpoints.

**Acceptance criteria**:
- Test framework: Jest or Vitest (check what's available in ecosystem)
- Tests for all API endpoints (sites CRUD, environment, frontend management)
- Mock `executeMatrix()` to avoid spawning real processes
- Test structured error responses
- Test input validation
- Minimum 80% line coverage for `frontend/app.js`

### TEST-02: Integration tests for CLI JSON output

**Priority**: P2 | **Phase**: 3

Verify that `matrix --json` commands produce correct output.

**Acceptance criteria**:
- Shell-based or JS-based test runner
- Test `matrix list --json` output structure
- Test `matrix status --json` output structure
- Test `matrix info <site> --json` output structure
- Tests run against a live Docker environment (may be CI-only)

### TEST-03: Test runner in package.json

**Priority**: P1 | **Phase**: 3

One command to run all tests.

**Acceptance criteria**:
- `npm test` runs all unit tests
- `npm run test:integration` runs integration tests (optional, separate)
- Test configuration in `frontend/package.json` or root
- Coverage report generated

---

## FIX - Technical Debt and Code Cleanup

### FIX-01: Remove unused dependencies

**Priority**: P2 | **Phase**: 4

`axios` is imported in `frontend/app.js:4` but never used. Remove it.

**Acceptance criteria**:
- Remove `axios` from `frontend/package.json` dependencies
- Remove `const axios = require('axios')` from `frontend/app.js`
- `npm install` succeeds
- All existing functionality works

### FIX-02: Consolidate duplicated Bash functions

**Priority**: P2 | **Phase**: 4

Logging functions, docker-compose detection, and site helpers are duplicated between `matrix:1-43` and `scripts/common.sh`.

**Acceptance criteria**:
- `matrix` sources `scripts/common.sh` for shared functions
- No duplicated implementations of `log_info`, `log_success`, `log_warning`, `log_error`, docker-compose detection, `get_sites()`, `site_exists()`, `get_next_port()`
- All existing CLI commands work identically
- All scripts still work after consolidation

### FIX-03: Sanitize site names in database operations

**Priority**: P1 | **Phase**: 4

Site names are interpolated directly into SQL queries without escaping.

**Acceptance criteria**:
- All SQL queries use parameterized or escaped site names
- Validation enforced at entry points (create, remove, clone, reset, backup)
- No SQL injection possible via site name

### FIX-04: Fix WP-CLI volume mount

**Priority**: P2 | **Phase**: 4

`docker-compose.yml:83` mounts `./wp_:/var/www/html` instead of `./wp_<site_name>:/var/www/html`.

**Acceptance criteria**:
- WP-CLI container can access all site files
- `scripts/search-replace.sh` and `scripts/update-core.sh` work correctly
- Volume mount pattern matches actual site directories

---

## UI - Frontend Dashboard Enhancements

### UI-01: Real-time status indicators

**Priority**: P0 | **Phase**: 2

Site cards on dashboard show live container status (running/stopped/starting) without page refresh.

**Acceptance criteria**:
- Status badge updates via WebSocket events
- Visual states: running (green), stopped (gray), starting (yellow spinner), error (red)
- No full page reload needed for status changes

### UI-02: Operation progress feedback

**Priority**: P1 | **Phase**: 2

When a user clicks start/stop/create/remove, show progress feedback.

**Acceptance criteria**:
- Button shows spinner/loading state during operation
- Progress steps shown for create (pulling image, copying files, creating DB, starting)
- Success/failure toast notification on completion
- Button re-enabled after operation completes

### UI-03: Code quality check UI

**Priority**: P2 | **Phase**: 3

Dashboard UI for running and viewing code quality check results.

**Acceptance criteria**:
- "Run Checks" button per site and for all sites
- Progress indicator during check execution
- Results displayed in structured format (errors, warnings, files)
- Results persist until next check run

---

## SEC - Security Hardening

### REQ-password-exposure: Fix password exposure in process listings

**Priority**: Critical | **Phase**: 5

**Source**: FLOW_REVIEW.md (#10)

Replace all `-p"$PASSWORD"` CLI args with `-e MYSQL_PWD="$PASSWORD"` across matrix, common.sh, backup.sh, reset.sh, clone.sh — 11 call sites.

**Acceptance criteria**:
- No MySQL or mysqldump invocation passes the password as a CLI argument
- All call sites use `-e MYSQL_PWD="$PASSWORD"` via `$CONTAINER_RUNTIME exec` 
- Verified by searching for `-p"\$` patterns across all shell files
- Password not visible in `ps aux` output during database operations

### REQ-env-permissions: Harden .env file permissions

**Priority**: High | **Phase**: 5

**Source**: FLOW_REVIEW.md (#11)

After every `cat > .env` write (2 locations in matrix), add `chmod 600 "$PROJECT_ROOT/.env"`.

**Acceptance criteria**:
- `.env` created with 600 (owner read/write only) permissions
- Applied in both `setup_env()` and `repair_env()` functions
- No world-readable `.env` files after creation

### REQ-gitignore-env: Verify .gitignore covers .env and add pre-commit guard

**Priority**: High | **Phase**: 5

**Source**: FLOW_REVIEW.md (#3)

Check that `.env` and `wp_*/.env` are in `.gitignore`. Add a pre-commit hook that greps for `MYSQL_PASSWORD` and rejects the commit if found.

**Acceptance criteria**:
- `.gitignore` includes `.env` and `wp_*/.env` patterns
- Pre-commit hook rejects commits containing `MYSQL_PASSWORD` strings
- No credential leakage into git history

---

## INFRA - Shell Infrastructure and Tooling

### REQ-random-passwords: Generate random passwords at .env creation

**Priority**: High | **Phase**: 6

**Source**: FLOW_REVIEW.md (#4)

In `setup_env()`, replace hardcoded `wp_password`/`root_password` with `openssl rand -base64 16`. Fix the mismatch with `.env.example` too.

**Acceptance criteria**:
- Fresh `.env` created with random credentials
- `.env.example` updated to match (no stale hardcoded values)
- Each `setup_env` invocation produces different credentials
- No hardcoded passwords remain in `.env` creation paths

### REQ-die-error-handling: Standardize error handling with die()

**Priority**: High | **Phase**: 6

**Source**: FLOW_REVIEW.md (#5)

Define a `die()` function in helpers.sh that prints a message and exits 1. Audit functions using bare `exit 1` or silent `return 1` and route them through `die()` or a documented return convention.

**Acceptance criteria**:
- `die()` defined in `scripts/helpers.sh` with message + exit 1
- Bare `exit 1` calls audited and replaced with `die()` where appropriate
- `return 1` retained only for validation functions where caller may want to retry
- Consistent error protocol documented in comment block

### REQ-test-check-alias: Remove or fix the test/check alias

**Priority**: Medium | **Phase**: 6

**Source**: FLOW_REVIEW.md (#6)

Either delete the `test` case from the matrix dispatch or wire it to a real runner (PHPUnit/Jest). Add a comment documenting the check command's actual purpose.

**Acceptance criteria**:
- `./matrix test` either removed or runs real test runner
- `./matrix check` documented as running PHPCS/PHPStan
- No undocumented aliases in the dispatch switch

### REQ-health-json: Add --json support to health-check.sh

**Priority**: Medium | **Phase**: 6

**Source**: FLOW_REVIEW.md (#7)

Pass a `--json` flag from `matrix health` into `health-check.sh` and have it emit a JSON object matching the format of status/info commands.

**Acceptance criteria**:
- `./matrix health --json` emits valid JSON
- JSON structure matches existing status/info format
- Human-readable output remains the default
- `--json` flag documented in health command help

---

## ARCH - Architecture and Code Organization

### REQ-shared-bootstrap: Extract shared bootstrap to lib/bootstrap.sh

**Priority**: High | **Phase**: 7

**Source**: FLOW_REVIEW.md (#8)

**Implementation approach**: Variant B — extract a new `lib/bootstrap.sh` sourced by both `matrix` and `scripts/common.sh`.

Move the duplicated ~40 lines (DOCKER_COMPOSE detection, color/logger defs, .env loading) into a single `lib/bootstrap.sh`. Have both `matrix` and `common.sh` source it.

**Acceptance criteria**:
- `lib/bootstrap.sh` created containing shared bootstrap code
- `matrix` sources `lib/bootstrap.sh` instead of defining its own bootstrap
- `scripts/common.sh` also sources `lib/bootstrap.sh`
- No duplicated implementations of docker-compose detection, color/logger functions, or `.env` loading
- All existing CLI commands work identically after refactor
- All scripts still work after consolidation

### REQ-domain-modules: Split monolithic matrix into domain modules

**Priority**: High | **Phase**: 7

**Source**: FLOW_REVIEW.md (#9)

Create `lib/site.sh`, `lib/env.sh`, `lib/db.sh`, `lib/devtools.sh`. Move functions domain by domain — start with `db.sh` (cleanest boundary). Source all modules at the top of `matrix`. Keep one domain per PR/commit.

**Acceptance criteria**:
- `lib/site.sh` — site lifecycle functions (create, remove, edit, restore)
- `lib/env.sh` — environment functions (start, stop, setup, install, repair)
- `lib/db.sh` — database functions (import, export)
- `lib/devtools.sh` — dev tool functions (shell, WP-CLI, checks, xdebug, scaffold)
- `matrix` sources all modules at startup
- All 28+ commands work identically after refactor

### REQ-compose-abstraction: Formalize Docker/Compose abstraction

**Priority**: Medium | **Phase**: 7

**Source**: FLOW_REVIEW.md (#10)

Pick one path: always use Compose for up/down and `docker exec` for runtime ops. Remove the fallback to raw `docker start/stop`. Document the contract in a comment block.

**Acceptance criteria**:
- Compose used for all `up -d`, `down`, `restart` operations
- `docker exec` used for all runtime operations (shell, WP-CLI, mysql)
- No raw `docker start/stop` fallback code paths
- Contract documented in `scripts/compose-lib.sh` or `lib/bootstrap.sh`

### REQ-dispatch-array: Replace case dispatch with associative array

**Priority**: Medium | **Phase**: 7

**Source**: FLOW_REVIEW.md (#11)

Build a `declare -A COMMANDS` map of command → function_name. Derive `--help` output from it. This also enables `matrix help <cmd>`.

**Acceptance criteria**:
- `declare -A COMMANDS` at the top of dispatch
- `--help` output derived from COMMANDS map keys
- `matrix help <command>` works for any registered command
- Unknown commands give suggestion ("did you mean?") if close match found

---

## TEST-SH - Shell Script Testing

### REQ-per-site-credentials: Implement per-site credential isolation

**Priority**: High | **Phase**: 8

**Source**: FLOW_REVIEW.md (#12)

Generate unique `MYSQL_USER`/`MYSQL_PASSWORD` per site at create time. Store in `wp_<site>/.env` (site-local). Global `.env` holds only infrastructure secrets (root DB password, Redis). Update all DB call sites to read site-local env.

**Acceptance criteria**:
- Each site created with unique database credentials
- Credentials stored in `wp_<site>/.env` (site-local)
- Global `.env` contains only infrastructure secrets
- All DB operations read site-local credentials from the correct `wp_<site>/.env`
- Compromise of one site's WordPress instance does not expose other site databases

### REQ-rotate-secrets: Add matrix rotate-secrets command

**Priority**: Medium | **Phase**: 8

**Source**: FLOW_REVIEW.md (#13)

Script that regenerates site passwords, runs `ALTER USER` inside the running container, updates `wp-config.php`, and rewrites `wp_<site>/.env` atomically.

**Acceptance criteria**:
- `matrix rotate-secrets` command registered in dispatch
- Regenerates credentials for all sites or specified site
- Runs `ALTER USER` inside MySQL container to update database user
- Updates `wp-config.php` with new credentials
- Writes new credentials to `wp_<site>/.env` atomically
- Rollback on failure (no partial credential update)

### REQ-shell-tests: Add shell script test coverage with bats

**Priority**: Medium | **Phase**: 8

**Source**: FLOW_REVIEW.md (#14)

Install bats-core. Write tests for: site creation/removal, port allocation, validation functions, DB import/export happy path. Target critical paths first, not full coverage.

**Acceptance criteria**:
- bats-core installed (dev dependency)
- Tests for site name validation functions
- Tests for port allocation (`get_next_port`)
- Tests for site creation/removal happy path
- Tests for database import/export happy path
- `make test` or `npm run test:shell` runs bats tests

---

## Requirement Traceability

### Milestone 1 (COMPLETE)

| Req ID | Category | Phase | Priority | Depends On |
|--------|----------|-------|----------|------------|
| API-01 | API | 1 | P0 | - |
| API-02 | API | 1 | P0 | API-01 |
| API-03 | API | 1 | P1 | API-02 |
| API-04 | API | 1 | P1 | - |
| API-05 | API | 2 | P2 | API-02, WS-02 |
| API-06 | API | 2 | P2 | WS-03 |
| WS-01 | WS | 2 | P0 | API-02 |
| WS-02 | WS | 2 | P1 | WS-01 |
| WS-03 | WS | 2 | P2 | WS-01 |
| TEST-01 | TEST | 3 | P1 | API-02 |
| TEST-02 | TEST | 3 | P2 | API-01 |
| TEST-03 | TEST | 3 | P1 | TEST-01 |
| FIX-01 | FIX | 4 | P2 | - |
| FIX-02 | FIX | 4 | P2 | - |
| FIX-03 | FIX | 4 | P1 | - |
| FIX-04 | FIX | 4 | P2 | - |
| UI-01 | UI | 2 | P0 | WS-01 |
| UI-02 | UI | 2 | P1 | WS-02 |
| UI-03 | UI | 3 | P2 | API-05, UI-02 |

### Milestone 2 (ACTIVE)

| Req ID | Category | Phase | Priority | Depends On |
|--------|----------|-------|----------|------------|
| REQ-password-exposure | SEC | 5 | Critical | - |
| REQ-env-permissions | SEC | 5 | High | - |
| REQ-gitignore-env | SEC | 5 | High | - |
| REQ-random-passwords | INFRA | 6 | High | - |
| REQ-die-error-handling | INFRA | 6 | High | - |
| REQ-test-check-alias | INFRA | 6 | Medium | - |
| REQ-health-json | INFRA | 6 | Medium | - |
| REQ-shared-bootstrap | ARCH | 7 | High | - |
| REQ-domain-modules | ARCH | 7 | High | REQ-shared-bootstrap |
| REQ-compose-abstraction | ARCH | 7 | Medium | - |
| REQ-dispatch-array | ARCH | 7 | Medium | REQ-domain-modules |
| REQ-per-site-credentials | SEC | 8 | High | REQ-password-exposure |
| REQ-rotate-secrets | INFRA | 8 | Medium | REQ-per-site-credentials |
| REQ-shell-tests | TEST-SH | 8 | Medium | - |

---

*Last updated: 2026-05-29 after ingest-docs from FLOW_REVIEW.md, DFD.md, IMPROVEMENT_PLAN.md*
