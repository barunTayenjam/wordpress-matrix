# Phase 5 Plan 1: Foundation Fixes Summary

## One-liner

Fixed wp-cli volume mount, cross-platform port detection, .env fallback defaults, ensure_wp_cli_running helper, and removed duplicate case entries in matrix dispatch.

## Changes

### Task 1.1: Fix wp-cli service in docker-compose.yml
- **File:** `docker-compose.yml` (line 83)
- **Change:** Volume mount `./wp_:/var/www/html:rw` → `./:/var/www/html:rw`
- **Why:** `./wp_` directory doesn't exist; mounting project root gives wp-cli access to all `wp_*` site directories
- **Commit:** `ff9606d`

### Task 1.2: Add port_in_use(), ensure_wp_cli_running(), fix common.sh
- **File:** `scripts/common.sh`
- **Changes:**
  - Added `port_in_use()` — cross-platform port check using `lsof` on macOS, `ss` on Linux
  - Added `ensure_wp_cli_running()` — starts wp-cli container with `--profile tools` before exec
  - Replaced `ss -tln` in `get_next_port()` with `port_in_use "$max_port"`
  - Added `.env` fallback defaults in `create_database()`: `${MYSQL_USER:-wp_user}`, `${MYSQL_PASSWORD:-wp_password}`
- **Commit:** `d2309dc`

### Task 1.3: Fix ss -tln across matrix, frontend/matrix, health-check.sh + remove duplicates
- **Files:** `matrix`, `frontend/matrix`, `scripts/health-check.sh`
- **Changes:**
  - Added `port_in_use()` to `matrix` and `frontend/matrix`
  - Replaced `ss -tln` calls in all three files with `port_in_use()`
  - Removed first `"backup"` case entry (line 2256-2258) so scripts/backup.sh dispatch is reached
  - Removed duplicate `"info"` and `"check"` case entries (lines 2293-2298)
- **Commit:** `acc3775`

## Verification Results

All syntax checks pass. No `ss -tln` calls remain in port detection logic. All case entries appear exactly once.

## Deviations

None — plan executed exactly as written.

## Key Files

| File | Action | Commit |
|------|--------|--------|
| `docker-compose.yml` | Fixed wp-cli volume mount | `ff9606d` |
| `scripts/common.sh` | Added port_in_use(), ensure_wp_cli_running(), fixed get_next_port(), .env fallbacks | `d2309dc` |
| `matrix` | Added port_in_use(), fixed ss -tln, removed duplicate cases | `acc3775` |
| `frontend/matrix` | Added port_in_use(), fixed ss -tln | `acc3775` |
| `scripts/health-check.sh` | Fixed ss -tln → port_in_use() | `acc3775` |
