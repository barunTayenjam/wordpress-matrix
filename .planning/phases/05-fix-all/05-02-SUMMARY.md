# Phase 5 Plan 2: WP-CLI Integration & Dependent Scripts Summary

## One-liner

Fixed WP-CLI container name (wpcli→wp-cli), --path arguments (added wp_ prefix), and added ensure_wp_cli_running() startup calls across all four WP-CLI scripts.

## Changes

### Task 2.1: Fix cache-clear.sh and update-core.sh
- **Files:** `scripts/cache-clear.sh`, `scripts/update-core.sh`
- **Changes:**
  - `cache-clear.sh`: Added `ensure_wp_cli_running`, fixed `wpcli` → `wp-cli`, fixed `--path="/var/www/html/$site"` → `--path="/var/www/html/wp_$site"`
  - `update-core.sh`: Added `ensure_wp_cli_running`, fixed 2x `wpcli` → `wp-cli`, fixed 2x `--path` to include `wp_` prefix
- **Commit:** `3566fd2`

### Task 2.2: Fix search-replace.sh and clone.sh WP-CLI calls
- **Files:** `scripts/search-replace.sh`, `scripts/clone.sh`
- **Changes:**
  - `search-replace.sh`: Fixed `wpcli` → `wp-cli`, fixed `--path` to include `wp_` prefix, added `ensure_wp_cli_running` before exec
  - `clone.sh`: Fixed `wpcli` → `wp-cli`, fixed `--path` to include `wp_` prefix, added `ensure_wp_cli_running`
- **Commit:** `d582a3e`
- **Note:** search-replace.sh still has syntax error on line 6 and eval injection — deferred to Plan 05-03

## Verification Results

- No `wpcli` references remain in any of the four scripts
- All WP-CLI exec calls use correct service name `wp-cli`
- All `--path` arguments include `wp_` prefix
- `ensure_wp_cli_running` is called before every WP-CLI exec call
- Syntax checks pass for cache-clear.sh, update-core.sh, clone.sh (search-replace.sh syntax error is expected — fixed in Plan 05-03)

## Deviations

None — plan executed exactly as written.

## Key Files

| File | Action | Commit |
|------|--------|--------|
| `scripts/cache-clear.sh` | Fixed container name, --path, added ensure_wp_cli_running | `3566fd2` |
| `scripts/update-core.sh` | Fixed container name (2x), --path (2x), added ensure_wp_cli_running | `3566fd2` |
| `scripts/search-replace.sh` | Fixed container name, --path, added ensure_wp_cli_running | `d582a3e` |
| `scripts/clone.sh` | Fixed container name, --path, added ensure_wp_cli_running | `d582a3e` |
