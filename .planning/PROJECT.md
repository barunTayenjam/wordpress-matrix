# WordPress Matrix — Backend/Frontend Integration Overhaul

## What This Is

A local WordPress development platform that manages multiple isolated WordPress instances via Docker. The platform has a Bash CLI (`matrix`) for all management operations and an Express.js web dashboard for browser-based control. This project enhances the integration layer between the two — replacing fragile text parsing with a proper structured API, adding real-time container state updates via WebSocket, and expanding frontend coverage to the most-used management commands.

## Core Value

Developers can manage their WordPress sites from the browser with the same reliability and completeness as the CLI — no stale data, no missing commands, no guessing.

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

### Active

- [ ] Structured JSON API replacing text output parsing
- [ ] Real-time container status updates pushed to dashboard via WebSocket
- [ ] Complete frontend coverage for site lifecycle operations
- [ ] Complete frontend coverage for code quality checks
- [ ] Log streaming to the browser
- [ ] Proper error handling with structured error responses
- [ ] Testable code with unit tests for API layer

### Out of Scope

- Mobile-responsive dashboard redesign — current Bootstrap layout works, visual redesign is separate
- User authentication on the frontend — local dev tool, no auth needed
- Containerizing the frontend — intentionally runs on host for direct CLI access
- New WordPress management features (e.g., SSL provisioning, domain routing) — scope is integration only
- Replacing the Bash CLI — it remains the source of truth, API wraps it properly

## Context

The current frontend (`frontend/app.js`) interacts with the backend exclusively by spawning `matrix` CLI commands via `child_process.spawn()` and parsing their stdout text. The `parseSiteList()` function splits CLI output on whitespace patterns to extract site names and statuses — fragile and format-dependent. Socket.io is already a declared dependency but completely unused. Axios is declared but also unused.

The CLI (`matrix`, 1464 lines) is well-structured with consistent output patterns (colored log functions, table formatting). It handles site CRUD, environment management, code quality checks, database import/export, and frontend process management.

Key technical debt from codebase map:
- Duplicated code between `matrix` and `scripts/common.sh` (logging, docker detection, site helpers)
- Mutable `docker-compose.yml` modified in-place by awk
- WP-CLI volume mount mismatch
- No input sanitization for database operations
- Frontend hardcoded ports scattered across files

## Constraints

- **CLI remains source of truth**: API wraps the CLI; doesn't bypass it with direct Docker calls
- **Local-only**: No authentication, no TLS, runs on localhost
- **Node.js >= 16**: Must support the current engine requirement
- **Existing stack**: Express, Handlebars, Bootstrap 5.3 — no new frameworks
- **Backward compatible**: CLI must continue working independently of the frontend

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| CLI-first architecture (keep) | Proven reliable, frontend is optional layer | ✓ Good |
| socket.io for real-time updates | Already a dependency, purpose-built for this | — Pending |
| Wrap CLI rather than replace | Preserves existing functionality, incremental improvement | — Pending |

---
*Last updated: 2025-04-06 after initialization*
