# Roadmap - WordPress Matrix Backend/Frontend Integration Overhaul

## Overview

4 phases, sequential delivery. Each phase produces working, committable software. Phase 1 is the foundation — everything else depends on it.

---

## Phase 1: Structured API Layer

**Goal**: Replace fragile text parsing with structured JSON communication between CLI and frontend.

**Requirements**: API-01, API-02, API-03, API-04

**Duration estimate**: 2-3 sessions

### Tasks

1. **Add `--json` flag to `matrix` CLI**
   - Modify `list_sites()` to output JSON when `--json` is passed
   - Modify `show_status()` to output JSON when `--json` is passed
   - Modify `show_info()` to output JSON when `--json` is passed
   - Strip ANSI color codes from JSON output
   - Files: `matrix` (list_sites, show_status, show_info functions)

2. **Refactor `frontend/app.js` to use JSON parsing**
   - Replace `parseSiteList()` with `JSON.parse()` of CLI output
   - Update `executeMatrix()` to pass `--json` flag for list/status/info
   - Update all API endpoints to consume structured data
   - Files: `frontend/app.js`

3. **Add structured error responses**
   - Define error codes and response format
   - Update API error handlers to use consistent format
   - Add input validation middleware for site names, actions, PHP versions
   - Files: `frontend/app.js`

4. **Update client-side JS for new data format**
   - Update `frontend/public/js/app.js` if data shape changes
   - Update Handlebars templates if needed
   - Verify dashboard still renders correctly
   - Files: `frontend/public/js/app.js`, `frontend/views/dashboard.handlebars`

### Success Criteria

- [ ] `matrix list --json` outputs valid JSON with sites and services
- [ ] `matrix status --json` outputs valid JSON with service health
- [ ] `matrix info <site> --json` outputs valid JSON with site details
- [ ] Dashboard renders correctly using JSON data (no text parsing)
- [ ] All existing site operations work (create, start, stop, remove)
- [ ] Error responses follow consistent `{ success, error: { code, message } }` format
- [ ] Input validation rejects invalid site names and actions

### Key Files Modified

- `matrix` — Add JSON output mode to list, status, info functions
- `frontend/app.js` — Replace parseSiteList, add validation, structured errors
- `frontend/public/js/app.js` — Adapt to new data format if needed
- `frontend/views/dashboard.handlebars` — Adapt to new data format if needed

---

## Phase 2: Real-time WebSocket Updates

**Goal**: Container status changes and operation progress pushed to dashboard in real-time.

**Requirements**: WS-01, WS-02, UI-01, UI-02, API-05, API-06

**Duration estimate**: 2-3 sessions

### Tasks

1. **Initialize socket.io in `frontend/app.js`**
   - Import and configure socket.io on the Express HTTP server
   - Set up connection/disconnection handlers
   - Files: `frontend/app.js`

2. **Implement container status polling**
   - Periodic Docker status check (via `matrix status --json` or direct `docker ps`)
   - Emit `status.changed` events when container states change
   - Debounce rapid state changes
   - Files: `frontend/app.js`

3. **Implement operation progress streaming**
   - Modify `executeMatrix()` to stream progress events during long operations
   - Emit `site.creating`, `site.starting`, `site.stopping` events with progress steps
   - Emit `site.operation` on completion with success/failure
   - Files: `frontend/app.js`

4. **Add socket.io client to dashboard**
   - Include socket.io client library in `main.handlebars`
   - Connect on page load, disconnect on page unload
   - Update status badges on `status.changed` events
   - Show operation progress feedback (spinners, step indicators)
   - Files: `frontend/views/layouts/main.handlebars`, `frontend/public/js/app.js`

5. **Add code quality check progress (API-05)**
   - Check operations emit progress via WebSocket
   - Results pushed on completion
   - Files: `frontend/app.js`

6. **Add log streaming endpoint (API-06)**
   - Subscribe/unsubscribe model for log streaming
   - `logs.data` events pushed to subscribed clients
   - Files: `frontend/app.js`

### Success Criteria

- [ ] socket.io connected and events flowing to browser
- [ ] Container status updates appear in dashboard within 5-10 seconds of change
- [ ] Starting/stopping a site shows real-time status change (no page reload)
- [ ] Create operation shows progress steps in dashboard
- [ ] Check operation shows running state in dashboard
- [ ] Log streaming works for subscribed sites

### Key Files Modified

- `frontend/app.js` — socket.io server, status polling, progress streaming, log streaming
- `frontend/public/js/app.js` — socket.io client, status updates, progress UI
- `frontend/views/layouts/main.handlebars` — socket.io client script
- `frontend/views/dashboard.handlebars` — status badge updates, progress indicators

---

## Phase 3: Testing & Code Quality UI

**Goal**: Unit test coverage for API layer, integration tests for CLI JSON output, check results UI.

**Requirements**: TEST-01, TEST-02, TEST-03, UI-03

**Duration estimate**: 1-2 sessions

### Tasks

1. **Set up test framework**
   - Install Jest or Vitest in `frontend/`
   - Configure test runner in `frontend/package.json`
   - Add `npm test` script
   - Files: `frontend/package.json`, `frontend/jest.config.js` or similar

2. **Write unit tests for API layer**
   - Mock `executeMatrix()` for all endpoint tests
   - Test `/api/sites` with JSON data
   - Test `/api/sites/:action` for create, start, stop, remove
   - Test error handling and validation
   - Test `/api/environment/:action`
   - Files: `frontend/tests/` or `frontend/__tests__/`

3. **Write CLI JSON output tests**
   - Test `matrix list --json` structure
   - Test `matrix status --json` structure
   - Test `matrix info <site> --json` structure
   - Files: `tests/cli/` or similar

4. **Add code quality check UI**
   - "Run Checks" button per site
   - Progress display during check execution
   - Structured results display (errors, warnings, counts)
   - Files: `frontend/views/dashboard.handlebars`, `frontend/public/js/app.js`

### Success Criteria

- [ ] `npm test` passes with 80%+ coverage on `frontend/app.js`
- [ ] All API endpoints have unit tests
- [ ] Error cases covered in tests
- [ ] CLI JSON output validated by integration tests
- [ ] Dashboard can trigger and display code quality checks

---

## Phase 4: Polish & Technical Debt

**Goal**: Clean up unused code, consolidate duplications, fix known issues.

**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04

**Duration estimate**: 1-2 sessions

### Tasks

1. **Remove unused axios dependency (FIX-01)**
   - Remove from `frontend/package.json`
   - Remove `require('axios')` from `frontend/app.js`
   - Files: `frontend/package.json`, `frontend/app.js`

2. **Consolidate duplicated Bash functions (FIX-02)**
   - Refactor `matrix` to source `scripts/common.sh` for shared functions
   - Remove duplicated logging, docker-compose detection, site helpers from `matrix`
   - Verify all CLI commands still work
   - Files: `matrix`, `scripts/common.sh`

3. **Sanitize site names in SQL (FIX-03)**
   - Add escape/validate function for site names used in SQL
   - Apply to all SQL queries in `matrix` and `scripts/*.sh`
   - Files: `matrix`, `scripts/common.sh`, `scripts/backup.sh`, `scripts/clone.sh`, `scripts/reset.sh`

4. **Fix WP-CLI volume mount (FIX-04)**
   - Correct volume mount in `docker-compose.yml`
   - Verify WP-CLI scripts work with corrected mount
   - Files: `docker-compose.yml`

5. **Final review and cleanup**
   - Verify all tests pass
   - Verify all operations work end-to-end
   - Update AGENTS.md with new architecture
   - Remove any dead code

### Success Criteria

- [ ] `npm test` passes
- [ ] No unused dependencies in `frontend/package.json`
- [ ] No duplicated functions between `matrix` and `scripts/common.sh`
- [ ] SQL queries use sanitized site names
- [ ] WP-CLI volume mount works for all sites
- [ ] All existing CLI and dashboard operations work correctly

---

## Dependency Graph

```
Phase 1 (API Layer)
  └── Phase 2 (WebSocket)
        └── Phase 3 (Testing + UI)
              └── Phase 4 (Polish)
```

Phase 4 tasks (FIX-01 through FIX-04) are independent of each other and can be done in any order. They're placed last because they're lower priority and lower risk.

---

*Last updated: 2025-04-06*
