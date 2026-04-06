# Quick Plan: 260406-pzd

**Task:** fix local URL not available for phpmyadmin and other services

**Created:** 2026-04-06

---

## Tasks

### Task 1: Fix localUrl for services in JSON output

**Files:**
- `matrix`

**Action:**
1. Updated `list_sites_json()` function to include `localUrl` for services
2. Added port mapping for services (phpMyAdmin: 8200)
3. Fixed parsing of colon-separated service config

**Verify:**
- Run `./matrix list --json` and verify services have localUrl field

**Done:**
- Services now include localUrl in JSON output
- phpMyAdmin shows http://localhost:8200
