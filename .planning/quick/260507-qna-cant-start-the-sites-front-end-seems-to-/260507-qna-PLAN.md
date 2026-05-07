---
phase: quick
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - matrix
autonomous: true
requirements: [fix-matrix-syntax]
must_haves:
  truths:
    - "matrix script executes without syntax errors"
    - "matrix list --json returns valid JSON with sites"
    - "Frontend dashboard shows running sites"
  artifacts:
    - path: "matrix"
      provides: "Fixed management script"
      contains: "no duplicate heredoc"
  key_links:
    - from: "frontend/app.js"
      to: "matrix"
      via: "executeMatrix('list', ['--json'])"
      pattern: "podman ps"
---

<objective>
Fix the `matrix` bash script syntax error that prevents ALL commands from working, making the frontend unable to list sites or execute any operations.

**Root Cause:** Lines 172-242 of `matrix` contain a DUPLICATE `cat << EOF` heredoc that's orphaned outside the `show_help()` function. The first `show_help()` (lines 117-171) is correct, but lines 172-242 are a dangling heredoc followed by `}` with no matching function opening. This causes every `./matrix` invocation to fail with exit code 2 and output the help text instead of executing commands.

**Evidence:**
- `bash -n matrix` reports: `line 242: syntax error near unexpected token '}'`
- Frontend logs show every command exits with code 2
- `matrix list --json` outputs help text (not JSON), causing: `SyntaxError: Unexpected token '🚀', "🚀 Simplif"... is not valid JSON`
- Containers ARE running fine (podman ps shows db, redis, phpmyadmin, wp_pimmsaa, nginx_pimmsaa all up)

Purpose: Restore full functionality to the management platform
Output: Working `matrix` script, responsive frontend dashboard
</objective>

<execution_context>
@/Users/baruntayenjam/.config/opencode/get-shit-done/workflows/execute-plan.md
@/Users/baruntayenjam/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<tasks>

<task type="auto">
  <name>Task 1: Remove duplicate orphaned heredoc from matrix script</name>
  <files>matrix</files>
  <action>
The `show_help()` function at lines 117-171 is correct (contains the full help text with heredoc, closes with `EOF` then `}`).

Lines 172-242 contain a DUPLICATE heredoc block that is ORPHANED — it starts with `cat << EOF` at line 172 (outside any function) and ends with `EOF` at line 241, followed by a stray `}` at line 242.

DELETE lines 172-242 entirely. The block starts right after the closing `}` of `show_help()` at line 171 and the next valid content is line 244 (`# Site discovery`).

Specifically, remove this exact block:
- Line 172: `    cat << EOF`
- Lines 173-241: The duplicate help text content
- Line 242: `}`

This should leave the file going from line 171 (`}`) directly to line 244 (`# Site discovery`).

After removing, also verify the second help block doesn't reference `${DEFAULT_PHP_VERSION}` like the first one does — the first block (kept) does use it correctly at line 124.

Also check: the first help block (lines 118-170) has `rest <name>` at line 131 which the duplicate doesn't have, confirming the duplicate is stale.
  </action>
  <verify>
    <automated>bash -n matrix 2>&1 && echo "SYNTAX OK"</automated>
  </verify>
  <done>bash -n matrix reports no errors; matrix script executes commands without syntax error</done>
</task>

<task type="auto">
  <name>Task 2: Verify matrix commands work and frontend shows sites</name>
  <files>matrix</files>
  <action>
After the syntax fix is confirmed, verify the end-to-end functionality:

1. Run `./matrix status` — should show actual system status (not help text). Expected: shows db, redis, phpmyadmin running, and wp_pimmsaa/nginx_pimmsaa running.

2. Run `./matrix list --json` — should return valid JSON with the pimmsaa site. Expected output like: `{"sites":[{"name":"pimmsaa",...}], "services":[...]}`

3. Test the frontend API: `curl -s http://localhost:8500/api/sites | python3 -m json.tool` — should return sites array with pimmsaa listed, not empty.

4. If the frontend has cached stale empty results, restart it: kill the process from `.frontend.pid` and start fresh with `cd frontend && PORT=8500 npm start &` (or via the matrix script if it's now working: `./matrix frontend restart`).

5. Verify the dashboard at http://localhost:8500 loads with sites visible by checking the API endpoint returns populated data.

If `matrix list --json` doesn't work because the `--json` flag handling or `list_sites_json()` function has issues, investigate and fix that too — the frontend depends on it.
  </action>
  <verify>
    <automated>./matrix list --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert len(d.get('sites',[])) >= 1, f'Expected sites, got: {d}'; print(f'OK: {len(d[\"sites\"])} sites found')" </automated>
  </verify>
  <done>All matrix commands work without syntax errors. Frontend API returns sites with pimmsaa listed. Dashboard at localhost:8500 shows the running site.</done>
</task>

</tasks>

<verification>
1. `bash -n matrix` — no syntax errors
2. `./matrix status` — shows real status (not help text)
3. `./matrix list --json | python3 -m json.tool` — returns valid JSON with sites
4. `curl http://localhost:8500/api/sites` — returns sites array with pimmsaa
</verification>

<success_criteria>
- `matrix` script has zero syntax errors
- All matrix commands execute properly (exit code 0 for valid commands)
- Frontend dashboard shows the pimmsaa site and running services
- No more "Command completed with code: 2" errors in frontend logs
</success_criteria>

<output>
After completion, create `.planning/quick/260507-qna-cant-start-the-sites-front-end-seems-to-/260507-qna-SUMMARY.md`
</output>
