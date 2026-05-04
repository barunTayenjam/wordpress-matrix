# Phase 5 Plan 3: Script-Specific Bug Fixes & Functional Completeness Summary

## One-liner

Fixed search-replace.sh syntax error and eval injection, implemented update_compose_file() and create_nginx_config() in common.sh, fixed backup.sh dead code and scope errors, and added .env fallback defaults across all scripts.

## Changes

### Task 3.1: Fix search-replace.sh syntax error + eval injection
- **File:** `scripts/search-replace.sh`
- **Changes:**
  - Fixed missing closing `)` on line 6 (`SCRIPT_DIR` assignment)
  - Replaced `eval "$CMD"` string-based execution with bash array `WP_CMD` + `"${WP_CMD[@]}"` expansion
  - Eliminated command injection vulnerability from user-provided `$SEARCH` and `$REPLACE` values
  - Script now passes `bash -n` syntax validation
- **Commit:** `99232a2`

### Task 3.2: Implement create_nginx_config() and update_compose_file() in common.sh
- **File:** `scripts/common.sh`
- **Changes:**
  - Replaced stub `update_compose_file()` with full implementation:
    - Uses `awk` to split `docker-compose.yml` at `volumes:` section
    - Adds Apache service definition with correct env vars, port assignment, and volume mount
  - Added `create_nginx_config()`:
    - Auto-detects Apache sites and skips nginx config creation
    - Creates proper nginx FastCGI config for PHP-FPM sites
    - Handles all required location blocks (PHP, dotfiles, try_files)
- **Commit:** `9f92db1`

### Task 3.3: Fix backup.sh bugs + add .env fallbacks to all remaining scripts
- **Files:** `scripts/backup.sh`, `scripts/clone.sh`, `scripts/reset.sh`
- **Changes:**
  - `backup.sh`:
    - Fixed dead `$?` checks under `set -e` — replaced with inline `if cmd; then...else...fi`
    - Removed `local` from top-level scope in compression section
    - Fixed log message for deleted backup directory after compression
    - Added `.env` fallback defaults: `${MYSQL_USER:-wp_user}`, `${MYSQL_PASSWORD:-wp_password}`
  - `clone.sh`: Added `.env` fallback defaults for database dump/import
  - `reset.sh`: Added `.env` fallback defaults for database dump and drop/create
- **Commit:** `8d05d59`

## Verification Results

- All 8 scripts pass `bash -n` syntax validation
- `search-replace.sh` no longer uses `eval` (only in comment)
- `WP_CMD` array-based execution in place
- `update_compose_file()` and `create_nginx_config()` are real implementations (not stubs)
- `.env` fallback defaults present in backup.sh, clone.sh, reset.sh, and common.sh
- No `eval` injection surface in any script

## Deviations

None — plan executed exactly as written.

## Key Files

| File | Action | Commit |
|------|--------|--------|
| `scripts/search-replace.sh` | Fixed syntax error, replaced eval with array execution | `99232a2` |
| `scripts/common.sh` | Implemented update_compose_file() and create_nginx_config() | `9f92db1` |
| `scripts/backup.sh` | Fixed dead $? checks, local scope, deleted dir ref, .env fallbacks | `8d05d59` |
| `scripts/clone.sh` | Added .env fallback defaults | `8d05d59` |
| `scripts/reset.sh` | Added .env fallback defaults | `8d05d59` |
