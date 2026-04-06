# Structure - WordPress Matrix Development Platform

## Root Directory Layout

```
wordpress-matrix/
├── matrix                      # Main CLI management script (1464 lines, Bash)
├── docker-compose.yml          # Docker service definitions (mutable, edited at runtime)
├── .env                        # Environment variables (gitignored)
├── .env.example                # Environment template
├── .frontend.pid               # PID file for frontend process
├── .gitignore                  # Aggressive gitignore rules
├── AGENTS.md                   # Agent/developer documentation
├── README.md                   # User-facing documentation
├── composer.json               # PHP quality tool dependencies
│
├── config/                     # Configuration files
│   ├── nginx/                  # Per-site Nginx configs
│   │   ├── asgard.conf         #   Nginx config for asgard site
│   │   ├── su21.conf           #   Nginx config for su21 site
│   │   ├── su26.conf           #   Nginx config for su26 site
│   │   ├── test-frontend.conf  #   Test config for frontend
│   │   └── testrm.conf         #   Test/remove config
│   └── mysql-init/             # MySQL initialization scripts
│
├── frontend/                   # Web management dashboard (Node.js/Express)
│   ├── app.js                  #   Express server with API routes (290 lines)
│   ├── healthcheck.js          #   Health check script (28 lines)
│   ├── Dockerfile              #   Docker build for frontend (not used in production)
│   ├── package.json            #   Node.js dependencies
│   ├── package-lock.json       #   Locked dependency versions
│   ├── .env / .env.example     #   Frontend-specific env vars
│   ├── .gitignore              #   Frontend-specific gitignore
│   ├── matrix                  #   Copy of main matrix script (for Docker build)
│   ├── public/                 #   Static web assets
│   │   └── js/
│   │       └── app.js          #     Client-side JavaScript (351 lines)
│   ├── views/                  #   Handlebars templates
│   │   ├── dashboard.handlebars #    Main dashboard template (234 lines)
│   │   ├── error.handlebars    #     Error page template
│   │   └── layouts/
│   │       └── main.handlebars #     Layout wrapper with Bootstrap (142 lines)
│   └── node_modules/           #   Installed dependencies (gitignored)
│
├── scripts/                    # Utility scripts (all Bash)
│   ├── common.sh               #   Shared functions: logging, docker detection, site helpers (96 lines)
│   ├── backup.sh               #   Database + file backup (148 lines)
│   ├── cache-clear.sh          #   Redis + WP cache clearing (95 lines)
│   ├── clone.sh                #   Full site cloning (79 lines)
│   ├── health-check.sh         #   System diagnostics (156 lines)
│   ├── reset.sh                #   Reset site to fresh install (105 lines)
│   ├── search-replace.sh       #   Database search/replace (81 lines)
│   └── update-core.sh          #   WordPress core updates (98 lines)
│
├── logs/                       # Runtime log files (gitignored)
│   └── frontend.log            #   Frontend server logs
│
├── ssl-certs/                  # SSL certificate storage
│
├── wp_asgard/                  # WordPress site: asgard (PHP 8.3, port 8201) [gitignored]
├── wp_su21/                    # WordPress site: su21 (PHP 7.4, port 8203) [gitignored]
└── wp_su26/                    # WordPress site: su26 (PHP 7.4, port 8202) [gitignored]
```

## Key File Locations

### Core Application Logic

| File | Lines | Role |
|------|-------|------|
| `matrix` | 1464 | Primary CLI, all management operations |
| `frontend/app.js` | 290 | Express API server, spawns matrix commands |
| `frontend/public/js/app.js` | 351 | Browser JavaScript for dashboard UI |
| `scripts/common.sh` | 96 | Shared bash functions for utility scripts |

### Configuration

| File | Role |
|------|------|
| `docker-compose.yml` | All Docker service definitions (modified at runtime) |
| `.env` | Database credentials, debug flags (gitignored) |
| `config/nginx/*.conf` | Per-site Nginx reverse proxy configs |

### Templates

| File | Role |
|------|------|
| `frontend/views/layouts/main.handlebars` | HTML layout shell with Bootstrap, sidebar, tabs |
| `frontend/views/dashboard.handlebars` | Dashboard content: stats, sites grid, services table, terminal |
| `frontend/views/error.handlebars` | Error page |

## Naming Conventions

### Directory Naming
- WordPress sites: `wp_<sitename>/` (e.g., `wp_asgard/`, `wp_su21/`)
- Site naming: alphanumeric + hyphens + underscores, must start with a letter
- Reserved names: `frontend`, `matrix`, and other system words

### Docker Service Naming
- WordPress containers: `wp_<sitename>` (e.g., `wp_asgard`)
- Nginx containers: `nginx_<sitename>` (e.g., `nginx_asgard`)
- System containers: `wp_db`, `wp_redis`, `wp_phpmyadmin`, `wp_phpcs`, `wp_phpstan`, `wp_cli`

### Database Naming
- Site databases: `<sitename>_db` (e.g., `asgard_db`, `su21_db`)
- Initial database: `wp_main`

### Script Naming
- Kebab-case for utility scripts: `cache-clear.sh`, `search-replace.sh`, `update-core.sh`

## File Size Distribution

| Category | Files | Approximate Total Lines |
|----------|-------|------------------------|
| Main CLI (matrix) | 1 | 1,464 |
| Frontend server | 1 | 290 |
| Frontend client JS | 1 | 351 |
| Frontend templates | 3 | 397 |
| Utility scripts | 8 | 758 |
| Config (docker-compose) | 1 | 193 |
| **Total (non-WP)** | **15** | **~3,453** |
| WordPress sites | 3 dirs | Standard WP install each |

## Git Tracking Strategy

The `.gitignore` aggressively excludes:
- All `wp_*/` directories (WordPress site files)
- `*.sql`, `*.sql.gz` (database dumps)
- `*.log`, `logs/` (log files)
- `.env` files (credentials)
- `vendor/`, `node_modules/` (dependencies)
- Media files (images, documents, archives)
- `wp-config.php`, `wp-config-*.php` (WordPress config with credentials)

Only the platform code (`matrix`, `frontend/`, `scripts/`, `config/`, docs) is tracked.
