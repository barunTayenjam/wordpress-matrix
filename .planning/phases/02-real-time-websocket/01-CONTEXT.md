# Phase 2: Real-time WebSocket Updates - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add real-time WebSocket updates to the dashboard using socket.io. Container status changes pushed to the browser in real-time without page refresh. Status polling via `matrix status --json` every 30 seconds. Event-driven architecture with socket.io server in frontend.

This phase does NOT include log streaming (deferred to future phase), testing, or technical debt cleanup.

</domain>

<decisions>
## Implementation Decisions

### Status Detection
- Primary: CLI polling via `matrix status --json` every 30 seconds
- Fallback: If Docker events available, use hybrid approach (lower latency)
- Keep it simple for now - polling is reliable and works with current architecture

### Polling Frequency
- Poll every 30 seconds (balanced between responsiveness and resource usage)
- User prefers lower resource usage over fastest updates

### Event Emission
- Emit `status.changed` event with full site/service state
- Clients receive full state and re-render the status area
- Simple and robust - no per-container event complexity

### Log Streaming
- NOT included in Phase 2
- Deferred to a future phase when there's more bandwidth
- Status updates are the priority

### WebSocket Events
- `status.changed` — Full state pushed to all connected clients
- `site.operation` — Operation start/complete (creating, starting, stopping)
- `site.operation.progress` — Progress steps during long operations
- Client auto-reconnects on disconnect

### UI Updates
- Status badges update in real-time without page reload
- Visual states: running (green), stopped (gray), starting (yellow spinner)
- Operation buttons show spinner during execution

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — WS-01, WS-02, UI-01, UI-02 requirements
- `.planning/ROADMAP.md` — Phase 2 section has tasks and success criteria

### Codebase Map
- `.planning/codebase/STACK.md` — socket.io is already in dependencies but unused
- `.planning/codebase/ARCHITECTURE.md` — Frontend architecture overview

### Source Code
- `frontend/app.js` — Express server, current API endpoints
- `frontend/public/js/app.js` — Client-side JS, loadDashboard(), siteAction()
- `frontend/views/layouts/main.handlebars` — HTML template, script includes
- `frontend/package.json` — socket.io dependency (unused)

</code_context>

<specifics>
## Specific Ideas

- socket.io already in package.json - just need to import and configure
- Use existing `executeMatrix('status', [], true)` to get JSON status
- 30-second polling interval via setInterval on server side
- On client: listen for 'status.changed' event, update currentData, re-render
- Status badge classes already exist in dashboard.handlebars (bg-success, bg-secondary)

</specifics>

<deferred>
## Deferred Ideas

- Log streaming via WebSocket — too much for this phase
- Docker events API integration — polling is sufficient for now
- Per-container granular events — full state is simpler

</deferred>

---

*Phase: 02-real-time-websocket*
*Context gathered: 2026-04-06*
