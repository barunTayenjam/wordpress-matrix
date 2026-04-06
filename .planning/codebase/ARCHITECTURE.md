# Architecture - WordPress Matrix Development Platform

## System Overview

WordPress Matrix is a **local development platform** that orchestrates multiple isolated WordPress instances via Docker. It follows a **CLI-first architecture** with an optional **web dashboard** layered on top.

```
┌─────────────────────────────────────────────────────┐
│                   Host Machine                       │
│                                                      │
│  ┌──────────────┐    ┌───────────────────────────┐  │
│  │  Frontend     │    │  matrix (Bash CLI)        │  │
│  │  (Express.js) │───>│  Main orchestrator        │  │
│  │  :8500        │    │  1464 lines               │  │
│  └──────────────┘    └──────────┬────────────────┘  │
│                                 │                    │
│                                 │ docker-compose     │
│                                 ▼                    │
│  ┌─────────────────────────────────────────────────┐ │
│  │            Docker Engine                        │ │
│  │  ┌──────┐ ┌───────┐ ┌──────────┐ ┌──────────┐ │ │
│  │  │ MySQL│ │ Redis │ │phpMyAdmin│ │  WP/PHP  │ │ │
│  │  │ :3306│ │       │ │  :8200   │ │  sites   │ │ │
│  │  └──────┘ └───────┘ └──────────┘ │ :8100+   │ │ │
│  │                                   └──────────┘ │ │
│  │  ┌──────────┐ ┌──────────┐                     │ │
│  │  │  Nginx   │ │ WP-CLI   │  (tools profile)    │ │
│  │  │ per-site │ │ PHPCS    │                     │ │
│  │  │ proxies  │ │ PHPStan  │                     │ │
│  │  └──────────┘ └──────────┘                     │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Architectural Pattern

**Orchestrator Pattern**: The `matrix` Bash script is the single source of truth for all operations. The frontend is a thin wrapper that delegates all work to `matrix` via `child_process.spawn()`.

- **No shared state** between frontend and CLI (frontend parses CLI text output)
- **No database** for management state (everything derived from filesystem and Docker)
- **No API abstraction** (frontend shells out to CLI commands)

## Core Layers

### Layer 1: Infrastructure (Docker Compose)

Defined in `docker-compose.yml`. Manages:
- Shared services: MySQL, Redis, phpMyAdmin (always-on)
- Per-site services: WordPress PHP-FPM + Nginx (dynamic)
- Tool services: PHPCS, PHPStan, WP-CLI (on-demand via Docker profiles)

All services communicate over a single bridge network `wp-net`.

### Layer 2: CLI Orchestrator (`matrix`)

The 1464-line Bash script at `matrix:1` is the core of the system. Key subsystems:

| Subsystem | Lines | Purpose |
|-----------|-------|---------|
| Configuration & helpers | 1-43 | Env loading, color output, docker-compose detection |
| Help system | 45-116 | Usage documentation |
| Site discovery | 119-154 | `get_sites()`, `site_exists()`, `get_next_port()` |
| Site CRUD | 157-587 | `create_site()`, `remove_site()`, `edit_site()` |
| Site listing | 340-440 | `list_sites()` - formatted table output |
| Environment management | 443-981 | `start_env()`, `stop_env()`, `setup_env()`, `install_env()` |
| Code quality | 730-811 | `run_checks()` - orchestrates PHPCS/PHPStan |
| Shell access | 814-854 | `access_shell()` - interactive container access |
| Database ops | 1106-1176 | `import_db()`, `export_db()` |
| Frontend mgmt | 1191-1309 | `manage_frontend()` - process lifecycle |
| Command dispatch | 1312-1464 | `main()` - routes commands to functions |

### Layer 3: Frontend Dashboard

Express.js server (`frontend/app.js`) that:
1. Renders Handlebars templates for the UI
2. Provides REST API endpoints
3. Spawns `matrix` commands via `child_process.spawn()`
4. Parses CLI text output into structured JSON

**Key architectural note**: The frontend does NOT have direct Docker access. It can only interact with Docker through the `matrix` CLI.

### Layer 4: Utility Scripts

Located in `scripts/`, each script is self-contained and sources `scripts/common.sh` for shared functions:

| Script | Purpose |
|--------|---------|
| `common.sh` | Shared functions (logging, docker-compose detection, site helpers) |
| `backup.sh` | Database + file backup with compression |
| `clone.sh` | Full site cloning (files + DB + URL replacement) |
| `reset.sh` | Reset site to fresh WordPress (with selective keep) |
| `update-core.sh` | WordPress core updates via WP-CLI |
| `cache-clear.sh` | Redis + WordPress cache clearing |
| `search-replace.sh` | Database search/replace via WP-CLI |
| `health-check.sh` | System health diagnostics |

## Data Flow

### Site Creation Flow

```
User → matrix create <name> [--php-version=X.X]
  ├─ Validate name (alphanumeric, not reserved)
  ├─ Validate PHP version (7.4|8.0|8.1|8.2|8.3)
  ├─ Create wp_<name>/ directory
  ├─ Docker run --rm wordpress:phpX.X-fpm → copy WordPress files
  ├─ Generate config/nginx/<name>.conf
  ├─ Calculate next available port (8100+)
  ├─ Append service definitions to docker-compose.yml
  ├─ Create database <name>_db via MySQL
  └─ docker-compose up -d wp_<name> nginx_<name>
```

### Frontend → Docker Flow

```
Browser → HTTP request to :8500
  → Express route handler
    → executeMatrix(command, args)
      → spawn('matrix', [command, ...args])
        → matrix script executes
          → docker-compose commands
        ← stdout/stderr captured
      ← Promise resolves with {success, stdout, stderr}
    ← JSON response or rendered template
  ← HTTP response to browser
```

## Key Design Decisions

1. **No reverse proxy (Traefik removed)**: Direct port mapping per site for simplicity
2. **Single Docker network**: All containers on `wp-net` bridge network
3. **Bind mounts for WordPress files**: Live editing without rebuild
4. **Filesystem as state store**: No management database; state derived from `wp_*/` directories and `docker-compose.yml`
5. **docker-compose.yml is mutable**: Site creation/removal edits the compose file in-place via awk
6. **Frontend runs on host**: Not containerized; spawns matrix CLI directly

## Entry Points

| Entry Point | Type | Description |
|-------------|------|-------------|
| `./matrix <command>` | CLI | Primary management interface |
| `http://localhost:8500` | Web | Dashboard UI |
| `http://localhost:8200` | Web | phpMyAdmin |
| `http://localhost:8201-8203` | Web | WordPress sites |
| `frontend/app.js` | Node.js | Express server startup |
| `scripts/*.sh` | CLI | Individual utility scripts |
