# Phase 1: Structured API Layer - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace fragile text parsing between `matrix` CLI and `frontend/app.js` with structured JSON communication. Add `--json` flag to core CLI read commands, refactor frontend to parse JSON instead of splitting text on whitespace patterns, add structured error responses, and validate API inputs.

This phase does NOT add WebSocket, testing, or technical debt cleanup — those are separate phases.

</domain>

<decisions>
## Implementation Decisions

### JSON Output Shape
- `matrix list --json` outputs `{ sites: [...], services: [...] }` as separate arrays (mirrors current parseSiteList output shape)
- Each site entry includes full detail: name, status (running/stopped/created), port, php_version, container_id (or null), local_url, disk_usage
- Each service entry includes: name, status, container_id (or null)
- `matrix status --json` outputs structured service health data
- `matrix info <site> --json` outputs everything available: PHP version, container status, container ID, port, disk usage, DB name, DB size, WordPress version (if detectable), nginx config path
- `matrix check <site> --json` outputs structured results per tool: `{ tool: 'phpcs'|'phpstan', files_scanned: N, errors: [{file, line, message, severity}], warnings: [{...}], totals: {errors, warnings} }`

### Error Handling
- Structured error JSON: `{ success: false, error: { code: string, message: string } }` on stdout
- Minimal error code set: `SITE_NOT_FOUND`, `SITE_ALREADY_EXISTS`, `INVALID_NAME`, `DOCKER_ERROR`, `COMMAND_FAILED`
- Always output JSON in --json mode, even when Docker is unreachable — `{ success: false, error: { code: 'DOCKER_ERROR', message: '...' } }`
- Frontend API layer maps CLI error codes to HTTP status codes: SITE_NOT_FOUND → 404, INVALID_NAME → 400, SITE_ALREADY_EXISTS → 409, DOCKER_ERROR → 503
- Non-zero exit code still set for errors

### API Endpoint Design
- Keep current REST shape: `POST /api/sites/:action` with `{siteName}` in body
- No URL restructuring — just improve validation and error responses
- PHP version passed as body param `phpVersion` in create requests, defaults to 8.3 if omitted
- No caching for `GET /api/sites` — call `matrix list --json` every time. Phase 2 WebSocket makes this real-time anyway.

### CLI Flag Behavior
- `--json` suppresses ALL human-readable output on stdout — only valid JSON on stdout
- All progress/info messages suppressed (or sent to stderr) when `--json` is active
- No ANSI color codes in JSON output
- `--json` only on core read commands: `list`, `status`, `info`, `check`
- Write commands (create, start, stop, remove) do NOT get `--json` — they return success/error via exit code + stderr text as they do now
- Frontend only uses `--json` when calling list, status, info, check

### Claude's Discretion
- Exact JSON field naming (camelCase vs snake_case) — follow existing JavaScript conventions in the codebase (camelCase)
- How to strip ANSI codes (sed, or avoid generating them) — whatever is cleanest in Bash
- Where to add the JSON flag parsing in the CLI's argument handling

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — API-01 through API-04 are the requirements for this phase
- `.planning/ROADMAP.md` — Phase 1 section has tasks and success criteria
- `.planning/PROJECT.md` — Project vision, constraints, key decisions

### Codebase Map
- `.planning/codebase/ARCHITECTURE.md` — System overview, data flow, entry points
- `.planning/codebase/CONCERNS.md` — Known issues including text parsing fragility (item 7), hardcoded ports (item 8)
- `.planning/codebase/CONVENTIONS.md` — Bash and JavaScript code style, API response format, error handling patterns
- `.planning/codebase/STRUCTURE.md` — File locations, naming conventions
- `.planning/codebase/STACK.md` — Dependencies (express, socket.io declared but unused, axios unused)
- `.planning/codebase/INTEGRATIONS.md` — Frontend API endpoints, how frontend talks to CLI
- `.planning/codebase/TESTING.md` — No tests exist, suggested approach with Jest

### Source Code
- `matrix` — 1464-line CLI, key functions: `list_sites()` (340-440), `show_status()`, `show_info()`, argument parsing (1312-1464)
- `frontend/app.js` — Express server (290 lines), `parseSiteList()` (81-123), `executeMatrix()` (30-78), all API routes
- `frontend/public/js/app.js` — Client-side JS (351 lines), consumes API data
- `frontend/views/dashboard.handlebars` — Dashboard template, renders site cards

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `executeMatrix()` in `frontend/app.js:30-78`: Already handles spawn, stdout/stderr capture, timeout, error handling. Only needs to add `--json` flag and switch from text parsing to JSON parsing.
- `parseSiteList()` in `frontend/app.js:81-123`: Will be REPLACED, but its output shape (`{ sites, services }`) is preserved in the new JSON format.
- Handlebars helpers (`eq`, `ne`) in `frontend/app.js:21-24`: Already registered, templates use them.
- Express middleware chain: cors, json body parsing, static files — all working, no changes needed.

### Established Patterns
- API response format: `{ success: true|false, ... }` — consistent across all endpoints
- Error responses: `{ success: false, error: message }` — needs upgrading to `{ success: false, error: { code, message } }`
- CLI argument parsing: `while [[ $# -gt 0 ]]; do ... case ... shift ... done` pattern in matrix
- Bash logging: `log_info`, `log_success`, `log_warning`, `log_error` with ANSI colors — must be suppressed in --json mode

### Integration Points
- `frontend/app.js` route handlers call `executeMatrix()` — this is where --json flag gets added
- `matrix` command dispatch at `matrix:1312-1464` routes to functions — --json flag needs to be parsed here and propagated
- `frontend/public/js/app.js` consumes API responses — may need field name updates if JSON shape changes
- `frontend/views/dashboard.handlebars` renders site cards — may need template updates if data fields change

</code_context>

<specifics>
## Specific Ideas

- Keep the `{ sites: [...], services: [...] }` shape from current parseSiteList — it works, just make it come from structured JSON instead of text parsing
- Full detail per site entry (name, status, port, php_version, container_id, local_url, disk_usage) means frontend gets everything in one call
- Error codes should be minimal — just 5-6 codes covering the main failure modes

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-structured-api-layer*
*Context gathered: 2026-04-06*
