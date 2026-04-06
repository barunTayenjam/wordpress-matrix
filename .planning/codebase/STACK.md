# Stack - WordPress Matrix Development Platform

## Languages

| Language | Usage | Files |
|----------|-------|-------|
| Bash | Main management CLI (`matrix`), all utility scripts | `matrix`, `scripts/*.sh` |
| JavaScript (Node.js) | Frontend web dashboard | `frontend/app.js`, `frontend/public/js/app.js`, `frontend/healthcheck.js` |
| Handlebars | HTML templating for dashboard | `frontend/views/**/*.handlebars` |
| PHP | WordPress site files (runtime, not authored here) | `wp_*/**` (gitignored) |
| YAML | Docker Compose configuration | `docker-compose.yml` |

## Runtime & Platform

- **Node.js** >= 16.0.0 (frontend server)
- **Docker** or **Podman** (container runtime)
- **docker-compose** or **podman-compose** (orchestration)
- **Host OS**: macOS / Linux (darwin/linux detected at runtime)

## Core Dependencies

### Frontend (`frontend/package.json`)

| Package | Version | Purpose |
|---------|---------|---------|
| express | ^4.18.2 | HTTP server framework |
| express-handlebars | ^7.1.2 | Template engine |
| axios | ^1.6.0 | HTTP client (declared but unused in current code) |
| dotenv | ^16.3.1 | Environment variable loading |
| cors | ^2.8.5 | Cross-origin support |
| socket.io | ^4.7.4 | WebSocket support (declared but unused in current code) |

### Dev Dependencies (Frontend)

| Package | Version | Purpose |
|---------|---------|---------|
| nodemon | ^3.0.1 | Auto-reload during development |

### PHP Quality Tools (`composer.json`)

| Package | Version | Purpose |
|---------|---------|---------|
| wp-coding-standards/wpcs | ^3.3 | WordPress coding standards for PHP CodeSniffer |
| phpstan/phpstan | ^2.1 | PHP static analysis |

## Docker Images Used

| Image | Usage | Profile |
|-------|-------|---------|
| `mysql:8.0` | Database server | Always-on |
| `redis:alpine` | Object cache | Always-on |
| `phpmyadmin/phpmyadmin:latest` | Database management UI | Always-on |
| `wordpress:php7.4-fpm` | WordPress sites (legacy) | Per-site |
| `wordpress:php8.0-fpm` | WordPress sites | Per-site |
| `wordpress:php8.1-fpm` | WordPress sites | Per-site |
| `wordpress:php8.2-fpm` | WordPress sites | Per-site |
| `wordpress:php8.3-fpm` | WordPress sites (default) | Per-site |
| `nginx:alpine` | Reverse proxy per site | Per-site |
| `wpengine/phpcs:latest` | PHP CodeSniffer | tools |
| `ghcr.io/phpstan/phpstan:latest` | PHPStan static analysis | tools |
| `wordpress:cli` | WP-CLI commands | tools |

## Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | All container service definitions |
| `.env` | Environment variables (DB creds, WP debug flags) |
| `.env.example` | Template for environment variables |
| `frontend/.env` | Frontend-specific env vars |
| `composer.json` | PHP dev tool dependencies |
| `frontend/package.json` | Node.js dependencies |
| `config/nginx/*.conf` | Per-site Nginx reverse proxy configs |
| `.frontend.pid` | PID tracking for frontend process |
| `.gitignore` | Aggressive gitignore (wp_*, .env, logs, media, vendor) |

## Build & Dev Commands

| Command | Purpose |
|---------|---------|
| `./matrix start` | Start core services (db, redis, phpmyadmin, frontend) |
| `./matrix create <name>` | Create new WordPress site |
| `./matrix start <name>` | Start specific site |
| `./matrix stop` | Stop all services |
| `./matrix status` | Show system status |
| `./matrix check <site>` | Run code quality checks |
| `cd frontend && npm start` | Start frontend on port 8500 |
| `cd frontend && npm run dev` | Start frontend with nodemon |

## Port Assignments

| Service | Port |
|---------|------|
| Frontend Dashboard | 8500 |
| phpMyAdmin | 8200 |
| WordPress sites | 8100+ (auto-assigned, currently 8201-8203) |
| MySQL | 3306 |
