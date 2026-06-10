# App Flow Report & Review

## Entry Point

`matrix` (2814 lines) is the single CLI entry. Parses `$1` via `case` dispatch to 28+ commands. For complex ops it runs inline; for maintenance it delegates to subprocess scripts.

## Source Graph

```
matrix (sources at load)
  ├── config/validation.sh     — site names, PHP versions, SQL sanitize
  ├── scripts/compose-lib.sh   — atomic docker-compose.yml mutations
  └── scripts/helpers.sh       — ports, networks, WP-CLI runner

scripts/*.sh (each sources)
  └── scripts/common.sh
        ├── config/validation.sh   (same file as above)
        └── scripts/helpers.sh     (same file as above)
```

## Dispatch Flow

```
User → matrix → case "$command"
  ├── inline: create, start, stop, remove, edit, status, info, shell,
  │            wp, import-db, export-db, check, xdebug, scaffold,
  │            frontend, repair, install, clean, logs, watch, preset
  └── subprocess: backup.sh, clone.sh, reset.sh, update-core.sh,
                  cache-clear.sh, search-replace.sh, health-check.sh
```

All subprocess scripts bootstrap through `common.sh` which re-sources `validation.sh` + `helpers.sh` — same libs `matrix` uses. `matrix` additionally sources `compose-lib.sh` (not needed by standalone scripts).

## Key Internal Functions (all in `matrix`)

| Domain         | Functions                                                                                                                                                 |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Site lifecycle | `create_site`, `remove_site`, `edit_site`, `restore_site`                                                                                                 |
| Environment    | `start_env`, `stop_env`, `setup_env`, `install_env`, `repair_env`, `clean_env`                                                                            |
| Database       | `import_db`, `export_db`                                                                                                                                  |
| Status/Info    | `show_status`, `show_status_json`, `show_urls`, `show_info_json`, `list_sites`, `list_sites_json`, `rest_site`, `show_logs`                               |
| Dev tools      | `access_shell`, `run_wp_cli`, `run_checks`, `run_tool_container`, `manage_frontend`, `configure_xdebug`, `watch_site`, `scaffold_project`, `list_presets` |

## External Systems Accessed

- **Docker/Podman** — container lifecycle, exec, inspect
- **Docker Compose** — up/down/restart/ps/config via `$DOCKER_COMPOSE`
- **MySQL** — direct `docker exec wp_db mysql ...` for DB creation, dumps
- **Filesystem** — `wp_<site>/` dirs, `config/nginx/`, `.env`, `logs/`
- **Frontend** — Node.js process managed via `manage_frontend`

---

## Review: Issues & Improvement Candidates

### 1. Monolithic `matrix` script (2814 lines)

One file handles site CRUD, environment lifecycle, database ops, code quality, WP-CLI proxying, frontend daemon management, and configuration. Functions share global state (`$COMPOSE_FILE`, `$CONTAINER_RUNTIME`, `$JSON_OUTPUT`) via mutation. No module boundaries.

**Suggestion:** Split into domain modules (e.g., `lib/site.sh`, `lib/env.sh`, `lib/db.sh`) sourced at startup — same pattern as `compose-lib.sh` and `helpers.sh` already demonstrate. Each module owns its global state and exposes a clear function API.

### 2. Duplicated setup in `matrix` vs `common.sh`

Both files independently detect `DOCKER_COMPOSE`/`CONTAINER_RUNTIME`, define identical color/logger functions, and load `.env`. The duplication is ~40 lines that must stay in sync.

**Suggestion:** Have `matrix` source `common.sh` instead of duplicating the bootstrap. Or extract a shared `lib/bootstrap.sh` that both use.

### 3. `matrix` has two code quality entry points

`./matrix check` and `./matrix test` both call `run_checks "$@"`. This aliasing is undocumented and `test` doesn't actually run tests — it runs PHPCS/PHPStan.

**Suggestion:** Remove the alias or route `test` to a real test runner (PHPUnit/Jest).

### 4. Dynamic dispatch via string matching, no validation layer

The `case "$command"` switch is a flat list. Unknown commands get a generic error. No subcommand help, no argparse library, no `$COMMAND` registry that could enable tab-completion or introspection.

**Suggestion:** Consider a simple dispatch table (associative array mapping command → function name) to decouple parsing from routing and enable `help <command>`.

### 5. `health-check.sh` runs as subprocess but has no `--json` support

`matrix health` calls `scripts/health-check.sh` directly, bypassing the `JSON_OUTPUT` machinery. All other status/info commands support `--json`.

**Suggestion:** Pipe output through a JSON formatter or pass `--json` flag to the script.

### 6. Error handling is inconsistent

Some functions use `return 1` (soft error, caller may continue), others `exit 1` (hard abort). `set -euo pipefail` is set at the top of `matrix` and `common.sh`, so an unhandled failure in a subshell or pipeline can exit prematurely without a clear message.

**Suggestion:** Adopt a consistent error protocol — e.g., `die()` that `exit 1` with a message, and `return 1` only for validation where the caller may want to retry.

### 7. No test coverage for shell scripts

The `./matrix test` command runs PHPCS/PHPStan on PHP code. The Bash code itself (2814 lines of `matrix` + 500+ lines of scripts) has zero automated tests. `bash -n matrix` only checks syntax.

**Suggestion:** ShellSpec or bats for unit/integration tests on critical paths (site creation, port allocation, validation).

### 8. `matrix` runs `docker-compose` commands, then falls back to direct `docker` commands

When Compose state is stale or missing, `matrix` falls back to `docker start/stop/restart` directly. This is pragmatic but creates two code paths for every lifecycle operation.

**Suggestion:** Consider a single abstraction — e.g., always operate on containers by name and use Compose only for `up -d` / `down`. The current pattern is already moving this direction; formalize it.

---

## Review: Secrets & Credential Handling

### 9. No credential generation — hardcoded default passwords

`.env` is created with hardcoded defaults in **two separate places** in `matrix`:

- `setup_env()` (L1417): `MYSQL_PASSWORD=wp_password` / `MYSQL_ROOT_PASSWORD=root_password`
- `repair_env()` (L2286): same defaults, repeated verbatim

`.env.example` has different hardcoded values (`wp_secure_2024` / `root_secure_2024`), so the example doesn't match what actually gets written. No `openssl rand` or password generation anywhere in the codebase.

**Suggestion:** Generate random passwords at `.env` creation time. Offer a `matrix rotate-secrets` command to re-key without rebuilding.

### 10. Passwords appear in process listings (`/proc/*/cmdline`)

Every MySQL and mysqldump invocation passes the password as a CLI argument:

```bash
$CONTAINER_RUNTIME exec wp_db mysql -u root -p"${MYSQL_ROOT_PASSWORD:-root}" -e "CREATE DATABASE ..."
$CONTAINER_RUNTIME exec wp_db mysqldump --no-tablespaces -u"${MYSQL_USER:-wp_user}" -p"${MYSQL_PASSWORD:-wp_password}" "$DB_NAME"
```

Any user on the host can read these via `ps aux` or `/proc`. This affects **all** database operations across `matrix`, `common.sh`, `backup.sh`, `reset.sh`, and `clone.sh` — at least **11 distinct call sites**.

**Suggestion:** Use `MYSQL_PWD` environment variable (MySQL reads it automatically) or pipe the password via `--defaults-extra-file` to keep it out of the process table. For `docker exec`, pass via `-e MYSQL_PWD=<pass>` instead of inline `-p`.

Example fix pattern:

```bash
# Instead of:
$CONTAINER_RUNTIME exec wp_db mysql -u root -p"$PASSWORD" -e "..."

# Use:
$CONTAINER_RUNTIME exec -e MYSQL_PWD="$PASSWORD" wp_db mysql -u root -e "..."
```

### 11. `.env` file permissions not hardened

The script creates `.env` via `cat > "$PROJECT_ROOT/.env"` without setting restrictive permissions. Default umask may leave it world-readable.

**Suggestion:** After writing, run `chmod 600 "$PROJECT_ROOT/.env"`. This is a one-line fix per write site (currently 2 in `matrix`).

### 12. `.env` keys shared across all sites

A single `.env` holds credentials for every site's database. There is no per-site credential isolation — all `wp_<site>` containers share the same `MYSQL_USER`/`MYSQL_PASSWORD` pair. A compromise of any site's WordPress instance gives access to all databases.

**Suggestion:** Generate per-site database credentials at site creation time. Store them in `wp_<site>/.env` (site-local) instead of the global `.env`. The global `.env` should only hold infrastructure secrets (root DB password, Redis, etc.).

### 13. WP-CLI credentials exposed in `docker run` environment

`run_wp_cli()` in `helpers.sh` passes `WORDPRESS_DB_USER` and `WORDPRESS_DB_PASSWORD` as `-e` flags to the ephemeral `wordpress:cli` container. These are visible to any process on the host during the container's lifetime.

**Suggestion:** Acceptable for an ephemeral container, but worth documenting that `docker history` on the `wordpress:cli` image does **not** retain these (they're runtime, not build args). Low severity.

### 14. No `.env` in `.gitignore` guarantee

If `.env` is accidentally tracked by git, credentials leak into the commit history.

**Suggestion:** Verify `.gitignore` includes `.env`. Add a pre-commit hook or CI check that rejects files containing `MYSQL_PASSWORD` patterns.

---

## Summary

The architecture is sound for a Bash project: single entry point, sourced libraries, delegated subprocesses. The main improvement lever is **splitting the monolith into domain modules** (already partially done with `compose-lib.sh` and `helpers.sh`) and **adding a shared bootstrap** to eliminate duplication between `matrix` and `common.sh`.

The most pressing security finding is **passwords in process listings** (#10 — 11+ call sites, trivially fixable with `MYSQL_PWD`). The most impactful structural improvement is **per-site credential isolation** (#12). Both are low-effort, high-value for a multi-tenant tool.

Response by Cloude

Critical
Phase 1 — Security (do first)
~2–3 hrs total
1
Fix password exposure in process listings 1–2 hrs
Replace all -p"$PASSWORD" CLI args with -e MYSQL_PWD="$PASSWORD" across matrix, common.sh, backup.sh, reset.sh, clone.sh. 11 call sites — search for 'mysqldump\|mysql.\_-p' to find them all.
✓
2
Harden .env file permissions 10 min
After every `cat > .env` write (2 locations in matrix), add `chmod 600 "$PROJECT_ROOT/.env"`. One line each.
✓
3
Verify .gitignore covers .env 15 min
Check that .env and wp\_\_/.env are in .gitignore. Add a pre-commit hook that greps for MYSQL*PASSWORD and rejects the commit if found.
✓
High value
Phase 2 — Quick wins
~3–4 hrs total
4
Generate random passwords at .env creation 30 min
In setup_env(), replace hardcoded wp_password/root_password with `openssl rand -base64 16`. Fix the mismatch with .env.example too.
✓
5
Standardize error handling with die() 1–2 hrs
Define a die() function in helpers.sh that prints a message and exits 1. Audit functions using bare `exit 1` or silent `return 1` and route them through die() or a documented return convention.
✓
6
Remove or fix the test/check alias 20 min
Either delete the `test` case from the dispatch or wire it to a real runner (PHPUnit/Jest). Add a comment documenting the check command's actual purpose.
✓
7
Add --json support to health-check.sh 45 min
Pass a --json flag from `matrix health` into health-check.sh and have it emit a JSON object matching the format of status/info commands.
✓
Architecture
Phase 3 — Structural cleanup
~1–2 days total
8
Extract shared bootstrap to lib/bootstrap.sh 1 hr
Move the duplicated ~40 lines (DOCKER_COMPOSE detection, color/logger defs, .env loading) into a single lib/bootstrap.sh. Have both matrix and common.sh source it.
✓
9
Split matrix into domain modules 1–2 days
Create lib/site.sh, lib/env.sh, lib/db.sh, lib/devtools.sh. Move functions domain by domain — start with db.sh (cleanest boundary). Source all modules at the top of matrix. Keep one domain per PR.
✓
10
Formalize the Docker/Compose abstraction 2–3 hrs
Pick one path: always use Compose for up/down and docker exec for runtime ops. Remove the fallback to raw `docker start/stop`. Document the contract in a comment block.
✓
11
Replace case dispatch with an associative array 2 hrs
Build a declare -A COMMANDS map of command → function_name. Derive --help output from it. This also enables `matrix help `.
✓
Ongoing
Phase 4 — Long-term hardening
schedule separately
12
Implement per-site credential isolation half day
Generate unique MYSQL_USER/MYSQL_PASSWORD per site at create time. Store in wp*/.env. Global .env holds only infrastructure secrets (root DB pass, Redis). Update all DB call sites to read site-local env.
✓
13
Add matrix rotate-secrets command 1 day
Script that regenerates site passwords, runs ALTER USER inside the running container, updates wp-config.php, and rewrites wp\_/.env atomically.
✓
14
Add shell script test coverage with bats ongoing
Install bats-core. Write tests for: site creation/removal, port allocation, validation functions, DB import/export happy path. Target critical paths first, not full coverage.
