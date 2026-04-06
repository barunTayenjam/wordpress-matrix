# Phase 3: Testing & Code Quality UI - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add unit tests for the API layer, CLI JSON integration tests, and a code quality check UI in the dashboard. Jest as the test framework. This provides test coverage and a UI for running code quality checks on WordPress sites.

This phase does NOT include Phase 4 technical debt items.

</domain>

<decisions>
## Implementation Decisions

### Test Framework
- **Jest** — Most common, well-documented, excellent for Express/Node.js
- Test location: `frontend/__tests__/` directory
- Configuration: `frontend/jest.config.js`

### Coverage Target
- 80%+ line coverage on `frontend/app.js`
- Priority on API endpoint tests and error handling

### CLI JSON Tests
- Shell-based or JS test runner
- Test against live Docker environment (or mocked)
- Test `matrix list --json`, `matrix status --json`, `matrix info <site> --json`

### Code Quality Check UI
- "Run Checks" button per site on dashboard Sites tab
- Global "Run All Checks" on Dashboard tab
- Progress display during check execution (using existing WebSocket operation events)
- Structured results display: errors count, warnings count, expandable list
- Results persist until next check run

</decisions>

<canonical_refs>
## Canonical References

### Requirements
- `.planning/REQUIREMENTS.md` — TEST-01, TEST-02, TEST-03, UI-03 requirements
- `.planning/ROADMAP.md` — Phase 3 section

### Source Code
- `frontend/app.js` — All API endpoints to test
- `frontend/public/js/app.js` — Client-side JS for check UI
- `frontend/views/dashboard.handlebars` — Dashboard template
- `matrix` — CLI commands to test

</code_context>

<specifics>
## Specific Ideas

- Mock executeMatrix in tests — don't spawn real processes
- Use supertest for HTTP endpoint testing
- Use jest's --coverage flag for coverage reports
- Check results displayed in a modal or expandable section

</specifics>

<deferred>
## Deferred Ideas

- Phase 4 technical debt (not part of this phase)

</deferred>

---

*Phase: 03-testing-quality-ui*
*Context gathered: 2026-04-06*
