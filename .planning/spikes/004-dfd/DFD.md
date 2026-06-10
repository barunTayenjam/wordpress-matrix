# WordPress Matrix — Data Flow Diagram (DFD)

## Level 0: Context Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Developer                                                  │
│  (Terminal / CLI)                                           │
│                                                             │
└────────┬──────────────────────────────────┬─────────────────┘
         │                                  │
         │ ./matrix create/start/stop/check │  ./matrix status --json
         │ ./matrix wp <site> <cmd>         │  ./matrix info <site> --json
         │ ./matrix shell <service>         │  ./matrix list
         ▼                                  ▼
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                 WordPress Matrix Platform                   │
│                                                             │
│  ┌─────────┐   ┌──────────┐   ┌────────┐   ┌───────────┐  │
│  │  matrix  │   │ Frontend │   │ Docker │   │   File    │  │
│  │  (Bash)  │──▶│(Express) │──▶│ Engine │──▶│  System   │  │
│  └─────────┘   └──────────┘   └────────┘   └───────────┘  │
│       │              │            │              │          │
│       ▼              ▼            ▼              ▼          │
│  ┌─────────┐   ┌──────────┐   ┌────────┐   ┌───────────┐  │
│  │  MySQL  │   │  Redis   │   │ Nginx  │   │ WordPress │  │
│  │   DB    │   │  Cache   │   │ Proxy  │   │   Sites   │  │
│  └─────────┘   └──────────┘   └────────┘   └───────────┘  │
│                                                             │
└────────┬──────────────────────────────────┬─────────────────┘
         │                                  │
         │ HTTP :8201, :8202...             │ HTTP :8500
         ▼                                  ▼
┌─────────────────────────┐    ┌─────────────────────────────┐
│                         │    │                             │
│   Browser (Site)        │    │   Browser (Dashboard)       │
│   http://localhost:8201 │    │   http://localhost:8500      │
│                         │    │                             │
└─────────────────────────┘    └─────────────────────────────┘
```

## Level 1: Key Data Flows

### Flow 1: Site Creation
```
Developer  ──./matrix create mysite──▶  matrix (Bash)
                                           │
                                           ├──▶ docker-compose.yml (append site service)
                                           ├──▶ mkdir wp_mysite/
                                           ├──▶ docker compose up -d wp_mysite
                                           │       │
                                           │       ├──▶ MySQL: CREATE DATABASE mysite_db
                                           │       ├──▶ WordPress: wp-config.php generated
                                           │       └──▶ Nginx: config/nginx/mysite.conf
                                           │
                                           ├──▶ WP-CLI: wp core install ...
                                           │
                                           └──▶ echo "Site created at :820X"
```

### Flow 2: Dashboard Request Flow
```
Browser ──GET /──▶ Frontend (Express :8500)
                      │
                      ├──▶ Render dashboard.hbs (Handlebars)
                      │
                      └──▶ GET /api/sites
                              │
                              └──▶ matrix list --json
                                      │
                                      ├──▶ docker ps (live containers)
                                      └──▶ docker-compose ps (compose state)
                                              
                              ◀── JSON response ──▶ Browser
                                                      │
                                                      └──▶ Socket.IO update
                                                           WebSocket push
```

### Flow 3: Code Quality Check
```
Browser ──POST /api/sites/check──▶ Frontend
                                      │
                                      ├──▶ matrix check <site>
                                      │       │
                                      │       ├──▶ phpcs run_tool_container
                                      │       ├──▶ phpstan analyse
                                      │       │
                                      │       └──▶ JSON output with results
                                      │
                                      └──▶ Response → Browser
                                               │
                                               └──▶ showNotification()
                                                    displayCheckResults()
```

### Flow 4: Database Operations
```
matrix shell db ──▶ mysql -h localhost -u wp_user -p
                      │
                      ├──▶ SELECT/INSERT/UPDATE/DELETE
                      │
                      └──▶ mysqldump (backup/export)

phpMyAdmin (:8200) ──▶ MySQL :3306
                          │
                          └──▶ Web GUI for DB management
```

## Level 2: Process Decomposition

### Frontend (Express) Internal Flows
```
                    ┌───────────────────┐
                    │   app.js Server   │
                    │   (Express + IO)  │
                    └───────┬───────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
     ┌────────────┐ ┌────────────┐ ┌────────────┐
     │  API Routes│ │ Socket.IO  │ │ Handlebars │
     │  /api/*    │ │  Events    │ │  Views     │
     └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
           │              │              │
           │    executeMatrix()          │
           │         │                  │
           ▼         ▼                  ▼
     ┌─────────────────────────────────────┐
     │         matrix (Bash CLI)           │
     └─────────────────────────────────────┘
```

### Bash CLI Internal Flows
```
                    ┌───────────────────┐
                    │   main()          │
                    │   (argument parse)│
                    └───────┬───────────┘
                            │
          ┌─────────────────┼──────────────────┐
          ▼                 ▼                   ▼
   ┌────────────┐   ┌──────────────┐   ┌──────────────┐
   │  validate  │   │  docker/     │   │  site ops    │
   │  site name │   │  compose     │   │  create/     │
   │  PHP ver   │   │  helpers     │   │  remove/edit │
   └────────────┘   └──────────────┘   └──────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌────────────┐   ┌──────────────┐   ┌──────────────┐
   │ compose_   │   │ container_   │   │ run_tool_    │
   │ add/remove │   │ is_running   │   │ container    │
   │ edit_site  │   │ ps_names     │   │ (phpcs/      │
   │            │   │              │   │  phpstan)    │
   └────────────┘   └──────────────┘   └──────────────┘
```

## Data Store Definitions

| Store | Technology | Data | Access Pattern |
|-------|-----------|------|----------------|
| MySQL DB | mysql:8.0 | WordPress content, users, options, site-specific DBs | Read/write via WP, direct SQL via phpMyAdmin |
| Redis Cache | redis:alpine | Object cache, page cache, sessions | Key-value, LRU eviction, 256MB max |
| File System | Host bind mount | WordPress files, configs, uploads, logs | Direct file I/O, Nginx serves static |
| Docker State | Docker daemon | Container status, network, volumes | docker inspect, docker ps |
| Compose Config | docker-compose.yml | Service definitions, ports, env vars | Parsed by matrix script |

## Key Data Flow Characteristics

- **Synchronous flows:** CLI commands (matrix create, start, stop) — developer waits for completion
- **Asynchronous flows:** Frontend polls matrix status via Socket.IO, dashboard updates in real-time
- **Data format:** JSON for API responses, shell stdout for CLI, raw HTTP for site traffic
- **Security boundary:** DB credentials flow from `.env` → docker-compose.yml → containers; never exposed to browser
