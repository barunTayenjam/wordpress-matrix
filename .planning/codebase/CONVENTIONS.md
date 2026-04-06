# Conventions - WordPress Matrix Development Platform

## Bash Code Style

### General Patterns

- **Shebang**: All scripts use `#!/bin/bash`
- **Error handling**: `set -euo pipefail` at the top of every script
- **Script template**: Every script follows this structure:
  ```bash
  #!/bin/bash
  # <Description>
  
  set -euo pipefail
  
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$SCRIPT_DIR/.."   # or "$SCRIPT_DIR" for matrix
  source "$SCRIPT_DIR/common.sh"  # for scripts/ only
  ```

### Variable Naming

- **UPPER_CASE** for constants and configuration: `SCRIPT_DIR`, `PROJECT_ROOT`, `COMPOSE_FILE`, `NC`
- **lower_case** for local/function variables: `site_name`, `php_version`, `port`
- **Boolean flags**: `true`/`false` as strings, compared with `==`: `[[ "$BACKUP_ALL" == true ]]`

### Logging

All output uses colored logging functions defined in both `matrix` and `scripts/common.sh`:

```bash
log_info()    "ℹ️  {message}"    # Blue
log_success() "✅ {message}"    # Green
log_warning() "⚠️  {message}"   # Yellow
log_error()   "❌ {message}"    # Red
```

No raw `echo` for user-facing messages.

### Docker Compose Detection

Both `matrix` and `scripts/common.sh` use the same detection pattern:

```bash
if command -v podman-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="podman-compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    log_error "Neither docker-compose nor podman-compose found"
    exit 1
fi
```

### Argument Parsing

Consistent `while [[ $# -gt 0 ]]; do ... case ... shift ... done` pattern with:
- `--flag=value` and `--flag value` support
- Unknown flag error with usage display
- Positional arguments captured as fallback

### Temporary Files

Safe temp file pattern: `local temp_file=$(mktemp)` followed by `mv "$temp_file" "$COMPOSE_FILE"`

## JavaScript Code Style (Frontend)

### Server-side (`frontend/app.js`)

- **CommonJS modules** (`require()`, not ESM imports)
- **No TypeScript**
- **Express patterns**: Standard middleware chain, JSON body parsing, static file serving
- **Error handling**: Try/catch with JSON error responses `{ success: false, error: message }`
- **Async/await** throughout (no callback patterns)
- **Console logging**: `console.log()` with `[Frontend]` prefix for server-side logs

### Client-side (`frontend/public/js/app.js`)

- **Vanilla JavaScript** (no framework)
- **Async/await** with `fetch()` for API calls
- **DOM manipulation**: Direct `document.getElementById()`, `querySelector()`
- **Global functions**: All handler functions are global (called from `onclick` attributes in templates)
- **State management**: Single `currentData` object with `sites` and `services` arrays
- **Error display**: Toast notifications via Bootstrap Toast component

### API Response Format

All API endpoints return consistent JSON:

```json
{
  "success": true|false,
  "sites": [...],
  "services": [...],
  "output": "...",
  "error": "..."
}
```

## Handlebars Templates

- **Layout**: Single layout at `frontend/views/layouts/main.handlebars` with `{{{body}}}` insertion point
- **Helpers**: Custom `eq` and `ne` helpers registered in `frontend/app.js:21-24`
- **Partials**: None used (monolithic templates)
- **CSS**: Inline `<style>` in layout, Bootstrap 5.3 CDN
- **Icons**: Bootstrap Icons via CDN

## Docker Compose Conventions

### Service Definition Pattern

Each WordPress site follows identical structure:

```yaml
# WordPress site: <name>
wp_<name>:
  image: wordpress:phpX.X-fpm
  container_name: wp_<name>
  restart: unless-stopped
  environment:
    WORDPRESS_DB_HOST: db:3306
    WORDPRESS_DB_USER: ${MYSQL_USER:-wp_user}
    WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD:-wp_password}
    WORDPRESS_DB_NAME: <name>_db
    WORDPRESS_DEBUG: ${WP_DEBUG:-true}
  volumes:
    - ./wp_<name>:/var/www/html
  networks:
    - wp-net
  depends_on:
    db:
      condition: service_healthy

nginx_<name>:
  image: nginx:alpine
  container_name: nginx_<name>
  restart: unless-stopped
  ports:
    - "PORT:80"
  depends_on:
    - wp_<name>
  volumes:
    - ./wp_<name>:/var/www/html:ro
    - ./config/nginx/<name>.conf:/etc/nginx/conf.d/default.conf:ro
  networks:
    - wp-net
```

### Environment Variable Defaults

Pattern: `${VAR:-default_value}` for safe fallbacks:
- `${MYSQL_USER:-wp_user}`
- `${MYSQL_PASSWORD:-wp_password}`
- `${MYSQL_ROOT_PASSWORD:-root}`
- `${WP_DEBUG:-true}`

## Nginx Configuration Pattern

All site configs follow the same template (`config/nginx/*.conf`):

```nginx
server {
    listen 80;
    server_name localhost;    # or _ for wildcard
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass wp_<site>:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires max;
        log_not_found off;
    }
}
```

## Error Handling Patterns

### Bash
- `set -euo pipefail` for strict error behavior
- `|| true` appended to commands where failure is acceptable
- `2>/dev/null` for suppressing expected stderr
- `if [[ $? -eq 0 ]]; then` for checking command success

### JavaScript (Server)
- Try/catch with `resolve({ success: false, ... })` instead of reject for command failures
- HTTP 500 for server errors, 400 for validation errors
- Process timeout handling with `matrixCmd.on('timeout')`

### JavaScript (Client)
- Try/catch around every `fetch()` call
- Toast notifications for success/error feedback
- Auto-dismiss after 5 seconds
