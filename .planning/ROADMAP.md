# Roadmap - WordPress Matrix Development Platform

---

## Milestone 1: Backend/Frontend Integration Overhaul ✅ COMPLETE

4 phases, sequential delivery. Each phase produces working, committable software. Phase 1 is the foundation — everything else depends on it.

---

### Phase 1: Structured API Layer [✓ COMPLETE]

**Goal**: Replace fragile text parsing with structured JSON communication between CLI and frontend.

**Requirements**: API-01, API-02, API-03, API-04

### Phase 2: Real-time WebSocket Updates [✓ COMPLETE]

**Goal**: Container status changes and operation progress pushed to dashboard in real-time.

**Requirements**: WS-01, WS-02, UI-01, UI-02, API-05, API-06

### Phase 3: Testing & Code Quality UI [✓ COMPLETE]

**Goal**: Unit test coverage for API layer, integration tests for CLI JSON output, check results UI.

**Requirements**: TEST-01, TEST-02, TEST-03, UI-03

### Phase 4: Polish & Technical Debt [✓ COMPLETE]

**Goal**: Clean up unused code, consolidate duplications, fix known issues.

**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04

---

## Milestone 2: Bash Hardening & Structural Cleanup

4 phases, sequential delivery by priority. Phase 1 (Security) must be done first. Phases 2-4 can be reordered within the milestone.

---

### Phase 5: Security (do first) ◆ IN PROGRESS

**Goal**: Eliminate credential exposure in process listings, harden file permissions, and prevent accidental credential commits.

**Requirements**: REQ-password-exposure, REQ-env-permissions, REQ-gitignore-env

**Duration estimate**: 2-3 hrs

**Plans**: 1 plan

Plans:
- [ ] 05-01-PLAN.md — Fix password exposure (16 call sites), harden .env permissions, add pre-commit hook

---

### Phase 6: Quick Wins

**Goal**: Generate random passwords, standardize error handling, fix dispatch alias, add --json to health-check.

**Requirements**: REQ-random-passwords, REQ-die-error-handling, REQ-test-check-alias, REQ-health-json

**Duration estimate**: 3-4 hrs

### Tasks

1. **Generate random passwords at .env creation** (#4)
   - In `setup_env()`, replace hardcoded `wp_password`/`root_password` with `openssl rand -base64 16`
   - Fix the mismatch with `.env.example` too
   - Files: `matrix` (setup_env), `.env.example`

2. **Standardize error handling with die()** (#5)
   - Define a `die()` function in `scripts/helpers.sh` that prints a message and exits 1
   - Audit functions using bare `exit 1` or silent `return 1` and route them through `die()` or a documented return convention
   - Files: `scripts/helpers.sh`, `matrix`, `scripts/*.sh`

3. **Remove or fix the test/check alias** (#6)
   - Either delete the `test` case from the dispatch or wire it to a real runner (PHPUnit/Jest)
   - Document the `check` command's actual purpose
   - Files: `matrix`

4. **Add --json support to health-check.sh** (#7)
   - Pass a `--json` flag from `matrix health` into `health-check.sh`
   - Have it emit a JSON object matching the format of status/info commands
   - Files: `scripts/health-check.sh`, `matrix`

### Success Criteria

- [ ] Fresh `.env` created with random credentials
- [ ] `die()` function defined and used consistently
- [ ] `./matrix test` either removed or runs real test runner
- [ ] `./matrix health --json` outputs valid JSON

---

### Phase 7: Structural Cleanup

**Goal**: Extract shared bootstrap, split monolithic matrix into domain modules, formalize Docker/Compose abstraction, replace case dispatch.

**Requirements**: REQ-shared-bootstrap, REQ-domain-modules, REQ-compose-abstraction, REQ-dispatch-array

**Duration estimate**: 1-2 days

### Tasks

1. **Extract shared bootstrap to lib/bootstrap.sh** (#8)
   - Move duplicated ~40 lines (DOCKER_COMPOSE detection, color/logger defs, .env loading) into a single `lib/bootstrap.sh`
   - Have both `matrix` and `scripts/common.sh` source it
   - Files: `lib/bootstrap.sh` (new), `matrix`, `scripts/common.sh`

2. **Split matrix into domain modules** (#9)
   - Create `lib/site.sh`, `lib/env.sh`, `lib/db.sh`, `lib/devtools.sh`
   - Move functions domain by domain — start with `db.sh` (cleanest boundary)
   - Source all modules at the top of `matrix`
   - Keep one domain per PR
   - Files: `lib/*.sh` (new), `matrix`

3. **Formalize the Docker/Compose abstraction** (#10)
   - Pick one path: always use Compose for up/down and `docker exec` for runtime ops
   - Remove the fallback to raw `docker start/stop`
   - Document the contract in a comment block
   - Files: `matrix`, `scripts/compose-lib.sh`

4. **Replace case dispatch with an associative array** (#11)
   - Build a `declare -A COMMANDS` map of command → function_name
   - Derive `--help` output from it
   - Enable `matrix help <cmd>`
   - Files: `matrix`

### Success Criteria

- [ ] `lib/bootstrap.sh` sourced by both `matrix` and `scripts/common.sh` — no duplicated bootstrap code
- [ ] Domain modules created and sourced; all 28+ commands work identically
- [ ] No raw `docker start/stop` fallback paths remain
- [ ] `declare -A COMMANDS` map drives dispatch; `matrix help` works

---

### Phase 8: Long-term Hardening

**Goal**: Per-site credential isolation, rotate-secrets command, shell test coverage.

**Requirements**: REQ-per-site-credentials, REQ-rotate-secrets, REQ-shell-tests

**Duration estimate**: Schedule separately (~2 days)

### Tasks

1. **Implement per-site credential isolation** (#12)
   - Generate unique `MYSQL_USER`/`MYSQL_PASSWORD` per site at create time
   - Store in `wp_<site>/.env` (site-local)
   - Global `.env` holds only infrastructure secrets (root DB pass, Redis)
   - Update all DB call sites to read site-local env
   - Files: `matrix`, `scripts/common.sh`, `scripts/*.sh`

2. **Add matrix rotate-secrets command** (#13)
   - Script that regenerates site passwords, runs `ALTER USER` inside the running container
   - Updates `wp-config.php` and rewrites `wp_<site>/.env` atomically
   - Files: `matrix` (new command)

3. **Add shell script test coverage with bats** (#14)
   - Install bats-core
   - Write tests for: site creation/removal, port allocation, validation functions, DB import/export happy path
   - Target critical paths first, not full coverage
   - Files: `tests/` (new directory)

### Success Criteria

- [ ] Each site has unique `MYSQL_USER`/`MYSQL_PASSWORD`
- [ ] Global `.env` holds only infrastructure secrets
- [ ] `matrix rotate-secrets` re-keys all site credentials atomically
- [ ] bats tests pass for critical shell paths

---

## Dependency Graph

```
Milestone 1 (Integration Overhaul) ✅
  └── Phase 1 → Phase 2 → Phase 3 → Phase 4

Milestone 2 (Bash Hardening) ◆ IN PROGRESS
  ├── Phase 5 (Security) — must be first
  ├── Phase 6 (Quick Wins)
  ├── Phase 7 (Structural Cleanup)
  └── Phase 8 (Long-term Hardening) — depends on Phase 5
```

Phase 6 and Phase 7 are independent of each other and could be parallelized. Phase 8 depends on Phase 5 (per-site credentials build on the password-exposure fix pattern).

---

*Last updated: 2026-05-29 after ingest-docs from FLOW_REVIEW.md*
