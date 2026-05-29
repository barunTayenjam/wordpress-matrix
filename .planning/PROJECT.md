# WordPress Matrix — Development Platform

## What This Is

A local WordPress development platform that manages multiple isolated WordPress instances via Docker. The platform has a Bash CLI (`matrix`) for all management operations and an Express.js web dashboard for browser-based control. Two active workstreams: (1) enhancing the frontend/CLI integration layer, and (2) hardening the Bash CLI itself — security, structure, and testability.

## Core Value

Developers can manage their WordPress sites reliably and securely from both CLI and browser — with no stale data, no exposed credentials, and no fragile text parsing.

## Requirements

### Validated

- ✓ Multi-site WordPress management via Docker Compose (asgard, su21, su26) — existing
- ✓ Site lifecycle: create, start, stop, remove with PHP version support — existing
- ✓ Bash CLI with 20+ commands for full platform control — existing
- ✓ Express.js web dashboard with Handlebars templates — existing
- ✓ Per-site Nginx reverse proxy with auto-assigned ports — existing
- ✓ MySQL, Redis, phpMyAdmin as shared services — existing
- ✓ Code quality tools (PHPCS, PHPStan) via Docker profiles — existing
- ✓ Utility scripts for backup, clone, reset, search-replace, cache-clear — existing

### Completed (Milestone 1: Backend/Frontend Integration Overhaul)

- ✓ Structured JSON API replacing text output parsing
- ✓ Real-time container status updates via WebSocket
- ✓ Complete frontend coverage for site lifecycle operations
- ✓ Code quality check results display in dashboard
- ✓ Log streaming to the browser
- ✓ Structured error responses
- ✓ Unit test coverage for API layer

### Active (Milestone 2: Bash Hardening & Structural Cleanup)

- [ ] Fix password exposure in process listings (11+ call sites)
- [ ] Harden .env file permissions (chmod 600)
- [ ] Verify .gitignore covers .env; add pre-commit credential guard
- [ ] Generate random passwords at .env creation time
- [ ] Standardize error handling with die()
- [ ] Remove or fix the `test`/`check` dispatch alias
- [ ] Add `--json` support to health-check.sh
- [ ] Extract shared bootstrap to `lib/bootstrap.sh` (Variant B)
- [ ] Split monolithic `matrix` (2814 lines) into domain modules
- [ ] Formalize Docker/Compose abstraction
- [ ] Replace case dispatch with associative array
- [ ] Implement per-site credential isolation
- [ ] Add `matrix rotate-secrets` command
- [ ] Add shell script test coverage with bats

### Out of Scope

- Mobile-responsive dashboard redesign — current Bootstrap layout works
- SSL/TLS provisioning — scope is platform hardening, not network security
- Containerizing the frontend — intentionally runs on host
- New WordPress management features (SSL, domain routing, multisite) — tracked as future feature proposals
- Replacing the Bash CLI — it remains the source of truth

## Context

### Architecture Baseline (from DFD.md)

The shell architecture has 5 layers:
- **L1**: `matrix` (2814 lines) — single CLI entry point dispatching 28+ commands
- **L2**: Sourced libraries — `config/validation.sh`, `scripts/compose-lib.sh`, `scripts/helpers.sh`
- **L3**: `scripts/common.sh` — bootstrapper for all standalone scripts
- **L4**: Standalone subprocess scripts — backup, clone, reset, update-core, health-check
- **L5**: External systems — Docker, MySQL, Redis, Nginx, WordPress, Frontend

### Known Structural Issues

- **Monolithic matrix script** (2814 lines, #1): Site CRUD, environment lifecycle, database ops, code quality, WP-CLI proxying, and frontend daemon management all in one file
- **Duplicated bootstrap** (#2): ~40 lines of docker-compose detection, color/logger defs, and .env loading duplicated between `matrix` and `scripts/common.sh`
- **Two code quality entry points** (#3): `./matrix check` and `./matrix test` both call `run_checks()` — undocumented alias
- **Inconsistent error handling** (#6): Mix of `return 1` and `exit 1` with no consistent protocol
- **No shell test coverage** (#7): 2814-line Bash script with zero automated tests

### Security Gaps

- **Passwords in process listings** (#10): Every MySQL/mysqldump invocation passes `-p"$PASSWORD"` as CLI argument — visible via `ps aux`
- **Default passwords** (#9): `.env` created with hardcoded `wp_password`/`root_password` — no `openssl rand` anywhere
- **Shared credentials** (#12): Single `MYSQL_USER`/`MYSQL_PASSWORD` pair for all sites — compromise of one site exposes all databases
- **Unhardened .env permissions** (#11): `.env` written without `chmod 600`

### Frontend Integration (Milestone 1 Complete)

The web dashboard (`frontend/app.js`) interacts with the backend via `matrix` CLI commands. All Milestone 1 integration features (JSON API, WebSocket, code quality UI, test coverage) are complete and deployed.

## Constraints

- **CLI remains source of truth**: API wraps the CLI; doesn't bypass it with direct Docker calls
- **Local-only**: No authentication, no TLS, runs on localhost
- **Node.js >= 16**: Must support the current engine requirement
- **Existing stack**: Express, Handlebars, Bootstrap 5.3 — no new frameworks
- **Backward compatible**: CLI must continue working independently of the frontend
- **Per-site isolation**: Database credentials must be unique per site
- **No credential in process table**: All MySQL invocations must use `MYSQL_PWD` env var or `--defaults-extra-file`
- **Shared bootstrap via lib/bootstrap.sh**: Both `matrix` and `common.sh` must source the same bootstrap library (Variant B)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| CLI-first architecture (keep) | Proven reliable, frontend is optional layer | ✓ Good |
| socket.io for real-time updates | Already a dependency, purpose-built for this | ✓ Implemented |
| Wrap CLI rather than replace | Preserves existing functionality, incremental improvement | ✓ Implemented |
| Extract lib/bootstrap.sh (Variant B) | Cleaner separation than sourcing common.sh from matrix | — Pending |
| Per-site credentials in wp_<site>/.env | Isolation prevents cross-site credential leakage | — Pending |

---
*Last updated: 2026-05-29 after ingest-docs from FLOW_REVIEW.md, DFD.md, IMPROVEMENT_PLAN.md*
