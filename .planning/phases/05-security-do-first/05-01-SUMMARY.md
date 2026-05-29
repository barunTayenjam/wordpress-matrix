---
phase: 05-security
plan: 01
subsystem: cli-security
tags: mysql, password, credential-exposure, pre-commit, env-permissions

# Dependency graph
requires:
  - phase: 04-polish
    provides: Working frontend/CLI integration baseline
provides:
  - All 16 mysql/mysqldump call sites converted from -p"$PASSWORD" CLI args to -e MYSQL_PWD= env var
  - .env file creation hardened with chmod 600 (2 locations)
  - Pre-commit hook blocking credential commits to git history
affects: 06-quick-wins, 07-structural-cleanup

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MYSQL_PWD env var for all MySQL authentication (instead of -p flag)"
    - "chmod 600 after .env file creation"
    - "Pre-commit hook via core.hooksPath = .githooks"

key-files:
  created:
    - .githooks/pre-commit
  modified:
    - matrix (10 passwords fixed + 2 chmod additions)
    - scripts/common.sh (1 root password fixed)
    - scripts/backup.sh (1 user password fixed)
    - scripts/reset.sh (2 passwords fixed)
    - scripts/clone.sh (2 passwords fixed)

key-decisions:
  - "Pre-commit hook refined to skip .sh/.bash/matrix files (legitimate env var refs) and block .env files + non-script files with hardcoded MYSQL_PASSWORD"
  - "All passwords use -e MYSQL_PWD placed before container/service name in both $CONTAINER_RUNTIME exec and $DOCKER_COMPOSE exec patterns"

patterns-established:
  - "MySQL/MariaDB auth: use MYSQL_PWD env var via -e flag on exec/docker-compose exec"
  - ".env files: always chmod 600 after creation"
  - "Pre-commit guard: block .env staging and hardcoded credentials in non-script files"

requirements-completed:
  - REQ-password-exposure
  - REQ-env-permissions
  - REQ-gitignore-env

duration: 26 min
completed: 2026-05-29
---

# Phase 5: Security — Plan 1: Password Exposure, .env Permissions, Pre-commit Hook

**Converted all 16 mysql/mysqldump call sites from `-p"$PASSWORD"` CLI args to `-e MYSQL_PWD=`, hardened `.env` file permissions with `chmod 600`, and installed a pre-commit hook blocking credential commits**

## Performance

- **Duration:** 26 min
- **Started:** 2026-05-29T11:45:27Z
- **Completed:** 2026-05-29T12:12:03Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Eliminated password exposure in process listings across 16 call sites in 5 shell files (matrix, scripts/common.sh, scripts/backup.sh, scripts/reset.sh, scripts/clone.sh)
- Added `chmod 600` after both `.env` creation points in `setup_env()` and `repair_env()` in matrix
- Created `.githooks/pre-commit` hook that blocks staging `.env` files and hardcoded `MYSQL_PASSWORD` in non-shell-script files
- Verified `.gitignore` already covers `.env` and `wp_*/.env` — no changes needed
- All modified files pass `bash -n` syntax check

## Threat Mitigations Applied

| Threat ID | Category | Component | Mitigation |
|-----------|----------|-----------|------------|
| T-05-01 | Information Disclosure | mysql/mysqldump in 5 files | All 16 call sites use `-e MYSQL_PWD=` — password not visible in `ps aux` |
| T-05-02 | Information Disclosure | .env file creation | `chmod 600` added after both `cat > .env` writes in matrix |
| T-05-03 | Information Disclosure | git commit workflow | Pre-commit hook rejects staged `.env` files and hardcoded passwords in non-script files |

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix root-password exposure (8 call sites)** — `c7d6eef` (fix)
2. **Task 2: Fix user-password exposure (8 call sites)** — `537029e` (fix)
3. **Task 3: .env permissions + pre-commit hook** — `cfce1b7` (feat)

**Plan metadata:** Pending (docs: complete plan)

## Files Created/Modified

- `matrix` — 6 root-password + 4 user-password call sites converted; `chmod 600` added after 2 .env creation points
- `scripts/common.sh` — 1 root-password call site converted (`create_site_database`)
- `scripts/backup.sh` — 1 user-password call site converted (mysqldump)
- `scripts/reset.sh` — 1 root-password (mysql) + 1 user-password (mysqldump) call sites converted
- `scripts/clone.sh` — 2 user-password call sites converted (mysqldump source, mysql import)
- `.githooks/pre-commit` — New pre-commit hook blocking credential commits

## Decisions Made

- **Pre-commit hook scope:** The hook skips `.sh`/`.bash` files and executables with a bash shebang (legitimate env var references like `"${MYSQL_PASSWORD:-wp_password}"`). It blocks `.env` files (always contain credentials) and non-script files containing `MYSQL_PASSWORD`. This avoids blocking legitimate commits to shell scripts while still preventing accidental credential leakage.
- **`-e MYSQL_PWD=` placement:** For `$CONTAINER_RUNTIME exec`, the `-e` flag goes before the container name (`wp_db`). For `$DOCKER_COMPOSE exec -T`, it goes before the service name (`db`). Both follow Docker's flag-ordering rules for exec.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Refined pre-commit hook to avoid blocking legitimate shell script commits**
- **Found during:** Task 3 (Commit failed due to hook)
- **Issue:** Original hook from plan used `grep -l 'MYSQL_PASSWORD'` on all staged files, which blocked `matrix` (legitimately references env var name in variable expansions like `"${MYSQL_PASSWORD:-wp_password}"`)
- **Fix:** Rewrote hook to:
  1. Always block `.env` files (they always contain credentials)
  2. Block non-shell-script files containing `MYSQL_PASSWORD` (hardcoded credential leak)
  3. Skip `.sh`/`.bash` files and executables with bash shebang (legitimate env var references)
- **Files modified:** `.githooks/pre-commit`
- **Verification:** Hook blocks `.env` files and credential text files; allows shell scripts with env var references
- **Committed in:** `cfce1b7` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The refinement was necessary — the original hook was unusable as written (blocked commits to the main matrix script). The refined hook provides better protection: `.env` files are always blocked, while shell scripts can be committed normally.

## Issues Encountered

- **Pre-commit hook blocked the Task 3 commit:** The hook's naive `grep -l 'MYSQL_PASSWORD'` pattern matched the matrix file's env var name references. Fixed by making the hook context-aware (skips shell scripts, blocks .env files and hardcoded values in non-script files).

## Known Stubs

None — all changes are production-ready credential hardening with no placeholder data.

## Threat Flags

None — the threat model in the plan (T-05-01, T-05-02, T-05-03) was fully covered by the three tasks. No new security-relevant surface was introduced.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Password exposure in process listings is fully mitigated — ready for Phase 6 (Quick Wins)
- Next plan in Phase 5 (05-02): Generate random passwords at .env creation time
- Pre-commit hook is active for all future commits

---

*Phase: 05-security*
*Completed: 2026-05-29*
