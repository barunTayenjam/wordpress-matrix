# Enhancement Research: WordPress Matrix

**Date:** 2026-04-06
**Mode:** gap-analysis

---

## Executive Summary

The WordPress Matrix app is a solid Docker-based WordPress management platform. Current gaps and enhancements fall into 4 categories:

| Category | Priority | Count |
|----------|----------|-------|
| UI/UX | High | 5 |
| API/CLI | High | 4 |
| DevOps | Medium | 3 |
| DX | Medium | 2 |

---

## High Priority

### 1. Site localUrl Not Populated

**Status:** 🔴 Gap

Sites show `localUrl: null` in JSON output despite having ports assigned in docker-compose.yml.

**Root cause:** `list_sites_json()` extracts port from nginx config but nginx containers aren't being matched correctly.

**Fix:** Update port extraction to check docker ps output directly.

---

### 2. WebSocket Real-time Updates Not Fully Utilized

**Status:** 🟡 Enhancement

Socket.io is configured but only polling status every 30s. Events like `site.operation` are emitted but frontend doesn't use them.

**Enhancement:** 
- Use WebSocket for instant site status changes
- Add live terminal output streaming
- Show real-time Docker container events

---

### 3. No Site Health Monitoring

**Status:** 🔴 Gap

No health check endpoints for sites. Can't tell if WordPress is actually responding.

**Enhancement:**
- Add HTTP health check for each site
- Display site response time in UI
- Alert if site is unresponsive

---

### 4. Missing Error Handling in create Site Flow

**Status:** 🔴 Gap

If Docker pull fails or port conflicts, error messages aren't user-friendly.

**Enhancement:**
- Pre-flight checks before creation
- Better error messages for port conflicts
- Rollback on failure

---

### 5. No Backup/Restore Functionality

**Status:** 🟡 Enhancement

No built-in backup for sites. Critical for production use.

**Enhancement:**
- `./matrix backup <site>` - tar+gz site directory
- `./matrix restore <site> <backup>` - restore from backup
- Auto-backup before updates

---

## Medium Priority

### 6. Terminal Tab Not Functional

**Status:** 🔴 Gap

Terminal tab in UI accepts commands but output isn't displayed properly.

**Fix:** Connect frontend terminal to backend execution with proper streaming.

---

### 7. No Theme/Plugin Management UI

**Status:** 🟡 Enhancement

Can only manage sites, not WordPress content.

**Enhancement:**
- List installed themes/plugins
- Activate/deactivate from UI
- Run wp-cli commands for theme management

---

### 8. Logs Viewer Limited

**Status:** 🟡 Enhancement

Can only tail container logs, no filtering or search.

**Enhancement:**
- Searchable log viewer
- Filter by log level
- Download logs

---

### 9. Code Quality Checks Not Integrated

**Status:** 🟡 Enhancement

phpcs/phpstan containers exist but not used from UI.

**Enhancement:**
- Run checks from UI button
- Display results in modal
- Link to line numbers in error output

---

## Low Priority

### 10. No Dark Mode

**Status:** 🟢 Enhancement

Only light theme available.

**Enhancement:** Add theme toggle in navbar.

---

### 11. No Mobile Responsive Design

**Status:** 🟢 Enhancement

Dashboard not optimized for mobile.

**Enhancement:** Improve mobile layout for site cards and tables.

---

### 12. No Keyboard Shortcuts

**Status:** 🟢 Enhancement

Power users would benefit from shortcuts (e.g., 'r' to refresh).

---

## Recommendations

### Quick Wins (do first)
1. Fix site localUrl - 1-2 hours
2. Wire up WebSocket events - 2-3 hours  
3. Terminal tab fix - 2 hours

### Medium Effort
4. Site health monitoring - 1 day
5. Backup/restore - 1-2 days

### Long Term
6. Theme/plugin management - 2-3 days
7. Full real-time sync - 1 week

---

## Files to Review

- `frontend/app.js` - WebSocket, API endpoints
- `matrix` - CLI commands
- `frontend/views/dashboard.handlebars` - UI
- `docker-compose.yml` - Service definitions
