# WordPress Matrix — Architecture Report

Generated from knowledge graph: 982 nodes, 1172 edges, 69 source files, 91 communities.

## System Overview

| Metric | Value |
|--------|-------|
| Total source files in graph | 69 |
| Files with functions/calls | 19 |
| Total function definitions | 93 |
| Total call edges | 248 |
| Total import edges | 7 |
| Community clusters | 82 (≥3 nodes)

## Top Files by Function Count

| # | File | Functions | Calls | Type | Community |
|---|------|-----------|-------|------|-----------|
| 1 | `frontend/public/js/app.js` | 61 | 76 | js | 0 |
| 2 | `scripts/graphify-shim/matrix.sh` | 50 | 141 | sh | 1 |
| 3 | `frontend/app.js` | 18 | 5 | js | 2 |
| 4 | `scripts/compose-lib.sh` | 10 | 8 | sh | 28 |
| 5 | `scripts/common.sh` | 8 | 4 | sh | 34 |
| 6 | `scripts/helpers.sh` | 6 | 2 | sh | 43 |
| 7 | `config/validation.sh` | 5 | 2 | sh | 52 |
| 8 | `.planning/phases/01-structured-api-layer/01-PLAN.md` | 4 | 0 | md | 16 |
| 9 | `scripts/cache-clear.sh` | 3 | 3 | sh | 62 |
| 10 | `scripts/update-core.sh` | 2 | 2 | sh | 71 |
| 11 | `scripts/backup.sh` | 2 | 2 | sh | 70 |
| 12 | `.planning/phases/03-testing-quality-ui/02-PLAN.md` | 2 | 0 | md | 25 |
| 13 | `frontend/__tests__/app.test.js` | 1 | 0 | js | 23 |
| 14 | `scripts/clone.sh` | 1 | 1 | sh | 78 |
| 15 | `scripts/reset.sh` | 1 | 1 | sh | 79 |

## Technology Split

| Layer | Files | Functions | Calls |
|-------|-------|-----------|-------|
| Frontend (JavaScript) | 3 | 80 | 81 |
| Backend (Bash) | 11 | 89 | 167 |
| Documentation (Markdown) | 5 | 9 | 0 |
| Other | 0 | 0 | 0 |

## File Dependencies

| Source | Dependency | Call Count |
|--------|------------|------------|
| `frontend/public/js/app.js` | `frontend/app.js` | 1 |

## Community Clusters

| Community | Node Count | File Count | Top Files |
|-----------|------------|------------|-----------|
| 0 | 62 | 1 | `app.js` |
| 1 | 52 | 1 | `matrix.sh` |
| 2 | 48 | 1 | `app.js` |
| 3 | 28 | 1 | `CONVENTIONS.md` |
| 4 | 28 | 1 | `REQUIREMENTS.md` |
| 5 | 26 | 1 | `CONCERNS.md` |
| 6 | 26 | 1 | `package.json` |
| 7 | 23 | 1 | `IMPROVEMENT_PLAN.md` |
| 8 | 23 | 1 | `260406-enhancements.md` |
| 9 | 20 | 1 | `02-PLAN.md` |
| 10 | 20 | 1 | `config.json` |
| 11 | 19 | 1 | `01-CONTEXT.md` |
| 12 | 19 | 1 | `260418-22ju-PLAN.md` |
| 13 | 19 | 1 | `ROADMAP.md` |
| 14 | 18 | 1 | `TESTING.md` |

## File Type Distribution

| Type | Files |
|------|-------|
| `sh` | 11 |
| `md` | 5 |
| `js` | 3 |

## Architecture Summary

- **Frontend:** 3 JS files with 80 functions — all Express/Handlebars/Socket.IO
- **Backend:** 11 Bash scripts with 89 functions — the `matrix` CLI is the largest (50 functions)
- **Call activity:** 248 total calls — frontend JS is call-heavy (76), matrix.sh is definition-heavy (50 funcs, 141 calls)
- **Architecture pattern:** Monorepo with a Bash CLI orchestrating Docker containers, managed via a Node.js frontend