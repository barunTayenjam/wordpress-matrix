---
phase: quick
plan: 260507-qna
subsystem: matrix-script
tags: [bugfix, bash, syntax-error, heredoc]
key_decisions:
  - Removed entire duplicate heredoc block (lines 172-242) rather than attempting partial fix
metrics:
  duration: 116s
  completed: "2026-05-07"
  tasks_total: 2
  tasks_completed: 2
  files_modified: 1
---

# Quick Task 260507-qna: Fix matrix script syntax error Summary

Removed duplicate orphaned heredoc from `matrix` bash script that caused all commands to fail with syntax errors and prevented the frontend from listing sites.

## Root Cause

The `show_help()` function (lines 117-171) was correct, but a duplicate `cat << EOF` heredoc block existed at lines 172-242 outside any function. This orphaned block ended with a stray `}` at line 242, causing `bash` to report a syntax error near unexpected token `}` and making every `./matrix` invocation fail with exit code 2.

## What Was Done

- **Task 1:** Deleted the duplicate orphaned heredoc block (lines 172-242) from the `matrix` script. The first `show_help()` function at lines 117-171 was kept intact — it contains the complete, correct help text including `${DEFAULT_PHP_VERSION}` variable expansion and the `rest <name>` command entry that the duplicate lacked.
- **Task 2:** Verified all matrix commands work correctly after the fix. Confirmed `./matrix status`, `./matrix list --json`, and the frontend API at `http://localhost:8500/api/sites` all return valid results.

## Verification Results

| Check | Result |
|-------|--------|
| `bash -n matrix` | SYNTAX OK |
| `./matrix status` | Shows db, redis, phpmyadmin, wp_pimmsaa, nginx_pimmsaa all running |
| `./matrix list --json` | Returns valid JSON with 1 site (pimmsaa) |
| `curl http://localhost:8500/api/sites` | Returns sites array with pimmsaa (running, port 8201) |

## Commits

| Commit | Message | Files |
|--------|---------|-------|
| 2edd76e | fix(quick-260507): remove duplicate orphaned heredoc from matrix script | matrix |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] `matrix` file exists and has no syntax errors (`bash -n matrix` → OK)
- [x] Commit `2edd76e` exists in git log
- [x] Frontend API returns populated sites data
- [x] No unexpected file deletions in commit
