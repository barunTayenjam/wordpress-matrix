# Synthesized Context

## Shell Script Architecture — Data Flow Diagram
- **Source**: DFD.md (DOC, precedence 1)

### Architecture Layers

**L1 — CLI Entry Point**: `matrix` (2814 lines) parses args and dispatches to 28+ commands. Runs inline for complex operations (create, start, stop, shell, WP-CLI, status) and delegates to subprocess scripts for maintenance operations (backup, clone, reset, update-core, cache-clear, search-replace, health-check).

**L2 — Sourced Libraries**:
- `config/validation.sh` — site name validation, PHP version validation, SQL ID sanitization, JSON output validator, RESERVED_NAMES, SUPPORTED_PHP_VERSIONS
- `scripts/compose-lib.sh` — compose file validation, atomic write, add/remove site from compose
- `scripts/helpers.sh` — site listing, port allocation, Docker network detection, WP-CLI runner utility

**L3 — Script Bootstrapper**: `scripts/common.sh` is sourced by every standalone script. It re-sources L2 libraries, loads .env, sets up runtime detection (Docker vs Podman), and defines shared DB/nginx helpers (get_site_port, create_database, update_compose, create_nginx_conf).

**L4 — Standalone Subprocess Scripts**:
- `scripts/backup.sh` — single-site database/file backup
- `scripts/reset.sh` — single-site reset
- `scripts/clone.sh` — multi-site cloning
- `scripts/update-core.sh` — WordPress core updates
- `scripts/cache-clear.sh` — cache clearing
- `scripts/search-replace.sh` — database search/replace
- `scripts/health-check.sh` — system health probe (containers, DB, Redis, ports, logs)

**L5 — External Systems**:
- Docker/Podman runtime — container lifecycle, exec, inspect
- Nginx (nginx_*) — reverse proxy per site
- MySQL (db) — shared database server
- Redis — in-memory cache
- WordPress (PHP-FPM, wp_<site>) — WordPress instances
- Frontend (Node/Express, localhost:8500) — web dashboard
- phpcs, phpstan — on-demand code quality tools
- WP-CLI — on-demand command-line tool
- docker-compose.yml — service definitions
- Filesystem — wp_<site>/ directories, config/nginx/, .env, logs/

### Data Flow Summary

```
User → matrix
  ├── (inline) → Docker/Compose/Containers
  ├── scripts/*.sh → common.sh → validation.sh + helpers.sh + .env
  └── frontend/(Node.js) → matrix (subprocess)
```

### Key Properties
- `matrix` is the single entry point — no bypass
- All standalone scripts bootstrap through `common.sh` which re-loads the same libs `matrix` uses
- Libraries are pure shell functions, no state, no side effects — composed at startup via `source`
- External systems accessed through Docker/Podman CLI or filesystem writes only

### Internal Function Domains (all in `matrix`)
- **Site lifecycle**: create_site, remove_site, edit_site, restore_site
- **Environment**: start_env, stop_env, setup_env, install_env, repair_env, clean_env
- **Database**: import_db, export_db
- **Status/Info**: show_status, show_status_json, show_urls, show_info_json, list_sites, list_sites_json, rest_site, show_logs
- **Dev tools**: access_shell, run_wp_cli, run_checks, run_tool_container, manage_frontend, configure_xdebug, watch_site, scaffold_project, list_presets
