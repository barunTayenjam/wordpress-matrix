# Shell Script Architecture — Data Flow Diagram

```text
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                      │
│                                   USER (CLI)                                         │
│                             ./matrix <command> [args]                                │
│                                                                                      │
└───────────────────────────────────┬──────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                      │
│   ███████╗███╗   ██╗████████╗██████╗ ██╗   ██╗    ██████╗  ██████╗ ██╗███╗   ██╗████████╗
│   ██╔════╝████╗  ██║╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝
│   █████╗  ██╔██╗ ██║   ██║   ██████╔╝ ╚████╔╝     ██████╔╝██████╔╝██║██╔██╗ ██║   ██║
│   ██╔══╝  ██║╚██╗██║   ██║   ██╔═══╝   ╚██╔╝      ██╔══██╗██╔══██╗██║██║╚██╗██║   ██║
│   ███████╗██║ ╚████║   ██║   ██║        ██║       ██║  ██║██║  ██║██║██║ ╚████║   ██║
│   ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝        ╚═╝       ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝
│                                                                                      │
│   ┌──────────────────────────────────────────────────────────────────────────────┐   │
│   │  **matrix** (2814 lines) — CLI dispatcher, 28+ commands                     │   │
│   │                                                                             │   │
│   │  _args parsed → `main()` → `case "$command" in` → dispatch                 │   │
│   │                                                                             │   │
│   │  Internal functions:                                                        │   │
│   │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│   │  │  Site lifecycle  │  Environment   │  Database    │  Dev tooling     │   │   │
│   │  ├─────────────────────────────────────────────────────────────────────┤   │   │
│   │  │  create_site()   │  start_env()   │  import_db() │  access_shell()  │   │   │
│   │  │  remove_site()   │  stop_env()    │  export_db() │  run_wp_cli()    │   │   │
│   │  │  edit_site()     │  setup_env()   │              │  run_checks()    │   │   │
│   │  │  restore_site()  │  install_env() │              │  manage_frontend │   │   │
│   │  │  clone → script  │  repair_env()  │              │  configure_xdebug│   │   │
│   │  │  reset → script  │  clean_env()   │              │  watch_site()    │   │   │
│   │  │  backup → script │  show_status() │              │  scaffold()      │   │   │
│   │  └─────────────────────────────────────────────────────────────────────┘   │   │
│   └──────────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                                  │
│                 ┌──────────────────┼──────────────────┐                               │
│                 ▼                  ▼                  ▼                               │
│   ┌────────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐  │
│   │  config/validation.sh  │  │  scripts/compose-lib.sh │  │  scripts/helpers.sh    │  │
│   │  (sourced at load)     │  │  (sourced at load)      │  │  (sourced at load)     │  │
│   ├────────────────────────┤  ├────────────────────────┤  ├────────────────────────┤  │
│   │  validate_site_name()  │  │  compose_validate()     │  │  get_sites()           │  │
│   │  validate_php_version() │  │  compose_atomic_write() │  │  site_exists()         │  │
│   │  sanitize_sql_id()     │  │  compose_add_site()     │  │  get_next_port()       │  │
│   │  validation_json()     │  │  compose_remove_site()  │  │  get_db_network()      │  │
│   │  RESERVED_NAMES        │  │                         │  │  port_in_use()         │  │
│   │  SUPPORTED_PHP_VERSIONS│  │                         │  │  run_wp_cli()          │  │
│   └────────────────────────┘  └────────────────────────┘  └────────────────────────┘  │
│                                    │                                                  │
│                 ┌──────────────────┘                                                  │
│                 ▼                                                                     │
│   ┌────────────────────────────────────────────────────────────────────────────┐      │
│   │  **scripts/common.sh** — Bootstrapper for standalone scripts              │      │
│   │                                                                           │      │
│   │  _Re-sources validation.sh + helpers.sh, defines shared helpers:_         │      │
│   │  ┌─────────────────────────────────────────────────────────────────────┐  │      │
│   │  │  get_site_port()    → reads port from compose or live container     │  │      │
│   │  │  create_database()  → mysql exec to CREATE DATABASE + GRANT         │  │      │
│   │  │  update_compose()   → appends wp/nginx blocks to docker-compose.yml │  │      │
│   │  │  create_nginx_conf()→ writes nginx site config to config/nginx/     │  │      │
│   │  └─────────────────────────────────────────────────────────────────────┘  │      │
│   └────────────────────────────────────────────────────────────────────────────┘      │
│                                    │                                                  │
│          ┌─────────────────────────┼─────────────────────────────┐                    │
│          ▼                         ▼                             ▼                    │
│   ┌──────────────┐   ┌──────────────────────┐   ┌───────────────────────────┐        │
│   │  backup.sh   │   │  clone.sh            │   │  health-check.sh          │        │
│   │  reset.sh    │   │  update-core.sh       │   │                           │        │
│   │  cache-clear │   │  search-replace.sh    │   │  _system health probe     │        │
│   │  .sh         │   │                      │   │                           │        │
│   │              │   │  _multi-site ops     │   │  containers + DB + Redis  │        │
│   │  _single-    │   └──────────────────────┘   │  + ports + logs           │        │
│   │  site maint  │                               └───────────────────────────┘        │
│   └──────────────┘                                                                   │
│                                                                                      │
│                                    │                                                  │
│                                    ▼                                                  │
│   ┌──────────────────────────────────────────────────────────────────────────────┐   │
│   │                          EXTERNAL SYSTEMS                                    │   │
│   ├──────────────────────────────────────────────────────────────────────────────┤   │
│   │  ┌────────────────────────────────────────────────────────────────────────┐  │   │
│   │  │                                                                        │  │   │
│   │  │     ┌──────────┐    ┌──────────┐    ┌────────┐    ┌───────────┐       │  │   │
│   │  │     │  Docker  │    │  Nginx   │    │  MySQL │    │   Redis   │       │  │   │
│   │  │     │ /Podman  │    │(nginx_*) │    │  (db)  │    │           │       │  │   │
│   │  │     │  runtime │    └──────────┘    └────────┘    └───────────┘       │  │   │
│   │  │     └──────────┘                                                      │  │   │
│   │  │                                                                        │  │   │
│   │  │     ┌────────────────────┐    ┌──────────────────────────┐            │  │   │
│   │  │     │  WordPress (PHP-FPM)│    │  Frontend (Node/Express) │            │  │   │
│   │  │     │  └─ wp_<site>      │    │  └─ localhost:8500       │            │  │   │
│   │  │     └────────────────────┘    └──────────────────────────┘            │  │   │
│   │  │                                                                        │  │   │
│   │  │     ┌──────────┐    ┌──────────┐    ┌────────────────────┐            │  │   │
│   │  │     │  phpcs   │    │  phpstan │    │  docker-compose.yml │           │  │   │
│   │  │     │ (on-     │    │ (on-     │    │  (service defs)    │            │  │   │
│   │  │     │  demand)  │    │  demand) │    └────────────────────┘            │  │   │
│   │  │     └──────────┘    └──────────┘                                       │  │   │
│   │  │                                                                        │  │   │
│   │  │     ┌──────────────────────────────────────────────────────────┐      │  │   │
│   │  │     │  Filesystem                                               │      │  │   │
│   │  │     │  ├─ wp_<site>/  (WordPress files per site)                │      │  │   │
│   │  │     │  ├─ config/nginx/<site>.conf  (Nginx vhosts)              │      │  │   │
│   │  │     │  ├─ config/validation.sh      (sourced rules)             │      │  │   │
│   │  │     │  ├─ .env                      (credentials, flags)        │      │  │   │
│   │  │     │  ├─ logs/activity.log         (audit trail)               │      │  │   │
│   │  │     │  └─ logs/frontend.log         (frontend daemon log)       │      │  │   │
│   │  │     └──────────────────────────────────────────────────────────┘      │  │   │
│   │  └────────────────────────────────────────────────────────────────────────┘  │   │
│   └──────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Layers

| Layer | Component | Role |
|-------|-----------|------|
| **L1** | `matrix` | CLI entry point. Parses args → dispatches to 28+ commands. Runs inline for complex ops, delegates to subprocess scripts for maintenance tasks. |
| **L2** | `config/validation.sh`, `compose-lib.sh`, `helpers.sh` | Sourced libraries. Validation rules, atomic compose file edits, shared network/port helpers, WP-CLI runner. |
| **L3** | `scripts/common.sh` | Bootstrapper for standalone scripts. Sourced by every `scripts/*.sh` — loads env, sets up runtime detection, re-sources L2 libs, defines DB/nginx helpers. |
| **L4** | `scripts/{backup,clone,reset,update-core,cache-clear,search-replace,health-check}.sh` | Standalone subprocess scripts. Each handles one maintenance operation. All source `common.sh`. |
| **L5** | Docker/Podman, MySQL, Nginx, Redis, WordPress (PHP-FPM), Frontend (Node.js), phpcs, phpstan, WP-CLI | External runtime systems and containers. |

---

## Data Flow Summary

```text
User ──► matrix ──┬──► (inline) ──► Docker/Compose/Containers
                  │
                  ├──► scripts/*.sh ──► common.sh ──┬──► validation.sh
                  │                                 ├──► helpers.sh
                  │                                 └──► .env
                  │
                  └──► frontend/ (Node.js) ──► matrix (subprocess)
```

- **`matrix`** is the single entry point — it either runs logic inline (create, start, stop, status, shell, WP-CLI) or delegates to a standalone script (backup, clone, reset, update, cache, search-replace, health).
- **All standalone scripts** bootstrap through `scripts/common.sh`, which re-loads the same libraries that `matrix` sources — keeping validation rules and helpers in sync.
- **Libraries are pure shell functions**, no state, no side effects — composed at script startup via `source`.
- **External systems** are always accessed through Docker/Podman CLI or filesystem writes — no in-process bindings.
