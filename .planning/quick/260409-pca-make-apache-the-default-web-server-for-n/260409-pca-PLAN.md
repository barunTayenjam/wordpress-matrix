---
must_haves:
  - Apache is the default web server for new WordPress sites
  - New site creation uses Apache unless nginx is explicitly specified
---

# Plan: Make Apache the default web server

## Tasks

### Task 1: Change default web server from nginx to apache

**Files:**
- `./matrix` (main script)

**Action:**
1. Add `DEFAULT_WEB_SERVER="apache"` after `DEFAULT_PHP_VERSION` (around line 12)
2. Change line 633 from `local web_server="nginx"` to `local web_server="${DEFAULT_WEB_SERVER:-apache}"`

**Verify:**
- Run `./matrix create testsite` and verify it uses Apache image

**Done:**
New WordPress sites will default to Apache.
