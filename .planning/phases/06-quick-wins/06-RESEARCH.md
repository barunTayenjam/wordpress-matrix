# Phase 6: Quick Wins - Technical Research

## Overview

Phase 6 addresses four independent shell-scripting improvements across the `matrix` CLI and supporting scripts. Each task has minimal cross-dependency — they can be planned in any order and executed in parallel where file access allows.

---

## 1. REQ-random-passwords: Generate Random Passwords at .env Creation

### Current State

Two locations write hardcoded passwords to `.env`:

1. **`setup_env()`** (matrix, line 1412-1427): `MYSQL_PASSWORD=wp_password`, `MYSQL_ROOT_PASSWORD=root_password`
2. **`repair_env()`** (matrix, line 2285-2297): Same hardcoded values

`.env.example` also has stale hardcoded values: `MYSQL_PASSWORD=wp_secure_2024`, `MYSQL_ROOT_PASSWORD=root_secure_2024`

### Approach

Replace the hardcoded values with `openssl rand -base64 16` in both locations. This produces 24-character base64 strings (128 bits of entropy), suitable for both MySQL passwords and WordPress auth keys.

```bash
# Generate random passwords
local wp_pass
wp_pass=$(openssl rand -base64 16 | tr -d '\n')
local root_pass
root_pass=$(openssl rand -base64 16 | tr -d '\n')
```

### Files to Modify
- `matrix`: `setup_env()` (~line 1417) and `repair_env()` (~line 2287)
- `.env.example`: Update to use placeholder/descriptive values instead of literal passwords

### Risks
- Existing `.env` files are NOT regenerated (only created if missing) — safe
- `openssl` is available on all platforms (macOS, Linux, Git Bash on Windows)

---

## 2. REQ-die-error-handling: Standardize Error Handling with die()

### Current State

- **`scripts/helpers.sh`**: Exists (88 lines) but does NOT have a `die()` function
- **`exit 1` calls**: 8 in `matrix`, 27 in `scripts/*.sh` — many are bare `exit 1` without error messages
- **`return 1` calls**: 20 in `scripts/*.sh` — some in validation functions (keep), others are early exits from failed operations

### Approach

Define `die()` in `scripts/helpers.sh`:
```bash
die() {
    local msg="${1:-Unknown error}"
    log_error "$msg"
    exit 1
}
```

Then audit all bare `exit 1` calls:
- `exit 1` in **dispatch context** (matrix lines 2606, 2609, 2642, 2645, 2664, 2667) — these follow `validate_site_name() || exit 1`, which is a standard shell pattern. These should remain as-is since `validate_site_name` already prints the error.
- `exit 1` in **script-level error handling** (scripts/*.sh files) — many are error conditions that should use `die()` instead.
- `return 1` in **validation functions** (validate_site_name, validate_php_version) — keep as `return 1` since callers may want to retry.
- `return 1` in **operation functions** (create_database, update_compose_file) — mixed; some are appropriate (caller handles retry), others should be `die()`.

### Classification Rule

| Pattern | Treatment | Reason |
|---------|-----------|--------|
| `validate_site_name || exit 1` | Keep as-is | Standard shell pattern, error already printed |
| Bare `exit 1` in scripts | Replace with `die("message")` | Error context is valuable |
| `return 1` in validation functions | Keep as-is | Caller may retry |
| `return 1` from operation functions | Evaluate case by case | Depends on whether caller handles failure |

### Files to Modify
- `scripts/helpers.sh`: Add `die()` function
- `scripts/*.sh`: Various `exit 1` → `die()` replacements
- `matrix`: Evaluate the 8 `exit 1` calls

---

## 3. REQ-test-check-alias: Remove or Fix the test/check Alias

### Current State

In the dispatch switch (matrix, lines 2773-2778):
```bash
"check"|"quality")
    run_checks "$@"
    ;;
"test")
    run_checks "$@"
    ;;
```

The `test` case is an undocumented alias that calls `run_checks` (PHPCS/PHPStan), NOT a test runner. This is misleading.

### Approach

**Option A: Remove the alias** — Delete the `test` case from the dispatch switch. Update the help text to clearly document `check` as PHPCS/PHPStan.

**Option B: Wire to real test runner** — Make `test` run `npm test` (Jest) or find/report available test commands.

**Recommendation: Option A** — simpler, avoids adding a dependency we don't need yet. The `check` command's purpose (PHPCS/PHPStan) is already documented in AGENTS.md. Add a comment above the check case block.

### Files to Modify
- `matrix`: Remove the `"test")` case block, add comment to `check` case
- `matrix`: Update help text to clarify `check` is for PHPCS/PHPStan

---

## 4. REQ-health-json: Add --json to health-check.sh

### Current State

- `matrix` dispatch (line 2755-2757): `"health") "$PROJECT_ROOT/scripts/health-check.sh" ;;` — no argument passthrough
- `scripts/health-check.sh` (161 lines): Human-readable output only, uses `echo` and `log_*` functions

### Approach

1. **Wire argument passthrough** in matrix dispatch: `"health") "$PROJECT_ROOT/scripts/health-check.sh" "$@" ;;`
2. **Add `--json` flag parsing** to health-check.sh at the top
3. **Emit JSON** matching the health-check content: containers_running, db_status, redis_status, sites, errors

### JSON Format

Based on existing `--json` patterns (matrix `status`, `info`), use the same structure:
```json
{
  "success": true,
  "data": {
    "containerRuntime": "docker",
    "composeTool": "docker-compose",
    "containersRunning": 5,
    "database": {
      "containerRunning": true,
      "connectionOk": true
    },
    "redis": {
      "containerRunning": true,
      "connectionOk": true
    },
    "sites": [
      {"name": "mysite", "running": true}
    ],
    "diskUsagePercent": 45,
    "diskAvailable": "100G",
    "errorCount": 0
  }
}
```

### Files to Modify
- `matrix`: Add `"$@"` to health dispatch call
- `scripts/health-check.sh`: Add `--json` flag support and JSON output path

---

## Dependency Analysis

| Task | Reads | Writes | Blocked By |
|------|-------|--------|------------|
| 1. Random passwords | matrix (setup_env, repair_env), .env.example | matrix, .env.example | Nothing |
| 2. die() error handling | scripts/helpers.sh, scripts/*.sh, matrix | scripts/helpers.sh, scripts/*.sh, matrix | Nothing (independent of task 1) |
| 3. test/check alias | matrix dispatch switch | matrix | Nothing |
| 4. health --json | matrix dispatch, scripts/health-check.sh | matrix, scripts/health-check.sh | Nothing |

All four tasks can be parallelized — they touch different files or independent sections of the same file (matrix dispatch is in lines 2755-2778, random password is in lines 1412-1427 and 2285-2297, no overlap).

## Common Pitfalls

1. **`exit 1` in scripts sourcing common.sh**: Some scripts call `exit 1` immediately after log_error — the message is already printed, so `die()` is a clean replacement
2. **`--json` flag collision**: Health check already uses `log_*` functions which emit ANSI color codes — JSON mode must suppress these
3. **`openssl rand` portability**: `-base64` flag is standard across OpenSSL 1.x and 3.x; avoid `-A` flag (not macOS compatible)
4. **`.env` regeneration**: Must NOT overwrite existing `.env` files — both `setup_env()` and `repair_env()` already check `[[ ! -f "$PROJECT_ROOT/.env" ]]` before writing
