---
phase: 01
plan: 01
wave: 1
depends_on: []
requirements: [API-01]
files_modified: [matrix]
autonomous: true
---

# Plan 01: Add --json Flag to matrix CLI

## Objective
Add a `--json` flag to the `matrix` CLI that makes `list`, `status`, `info`, and `check` commands output structured JSON instead of human-readable tables. When `--json` is active, stdout contains ONLY valid JSON — no colors, no progress messages, no ANSI codes.

## must_haves
- `matrix list --json` outputs `{ "sites": [...], "services": [...] }` with full detail per entry
- `matrix status --json` outputs structured service health JSON
- `matrix info <site> --json` outputs all available site details as JSON
- `matrix check <site> --json` outputs structured check results as JSON
- Error cases output `{ "success": false, "error": { "code": "...", "message": "..." } }` as JSON
- No ANSI color codes in JSON output
- Human-readable output remains the default (no behavior change without --json)

<task id="1">
<name>Add JSON output infrastructure to matrix script</name>
<read_first>
- matrix (lines 1-43: configuration, colors, logging helpers)
- matrix (lines 1312-1464: main() command dispatcher)
</read_first>
<action>
After the existing color definitions (line 19) and before `log_info()` definitions (line 22), add:

1. A global variable `JSON_OUTPUT=false` to track whether --json mode is active.

2. A helper function `output_json()` that takes a single argument (a JSON string) and echoes it to stdout. This function should be used by all JSON-outputting code paths:
```bash
output_json() {
    echo "$1"
}
```

3. A helper function `error_json()` that takes `code` and `message` arguments and outputs structured error JSON, then exits with code 1:
```bash
error_json() {
    local code="$1"
    local message="$2"
    printf '{"success":false,"error":{"code":"%s","message":"%s"}}\n' "$code" "$message"
    exit 1
}
```

4. Override the logging functions when `JSON_OUTPUT` is true. Add these AFTER the existing log_info/log_success/log_warning/log_error definitions (after line 25):
```bash
json_log_override() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        log_info() { :; }
        log_success() { :; }
        log_warning() { :; }
        log_error() { :; }
    fi
}
```

This function will be called after --json is detected in argument parsing.

5. In the `main()` function (line 1312), add `--json` detection in the argument preprocessing. Before the `case "$command"` block (before line 1322), add a loop that scans remaining arguments for `--json`:
```bash
local json_flag=false
local filtered_args=()
for arg in "$@"; do
    if [[ "$arg" == "--json" ]]; then
        json_flag=true
    else
        filtered_args+=("$arg")
    fi
done
if [[ "$json_flag" == true ]]; then
    JSON_OUTPUT=true
    json_log_override
fi
set -- "${filtered_args[@]}"
```

This strips `--json` from the argument list so it doesn't interfere with existing argument parsing, sets the global flag, and overrides logging functions.
</action>
<acceptance_criteria>
- matrix script contains `JSON_OUTPUT=false` variable definition
- matrix script contains `output_json()` function definition
- matrix script contains `error_json()` function definition
- matrix script contains `json_log_override()` function definition
- `main()` function detects and strips `--json` from arguments before dispatching
- Running `./matrix list --json` does not crash (may not output JSON yet, but should not error)
- Running `./matrix list` (without --json) produces identical output to current behavior
- Running `./matrix --json list` also works (flag can appear anywhere after command)
</acceptance_criteria>
</task>

<task id="2">
<name>Add list_sites_json() function for matrix list --json</name>
<read_first>
- matrix (lines 119-154: get_sites(), site_exists(), get_next_port())
- matrix (lines 340-440: list_sites() — current human-readable implementation)
- matrix (lines 4-42: docker-compose detection, color definitions)
</read_first>
<action>
Add a new function `list_sites_json()` BEFORE `list_sites()` (before line 340). This function queries Docker for container states and outputs structured JSON.

The function must:

1. Call `get_sites()` to get the list of site names.

2. For each site, collect:
   - `name`: site name (e.g., "asgard")
   - `status`: "running" or "stopped" — check via `$DOCKER_COMPOSE ps --format "{{.Names}}" | grep -q "wp_$site"`
   - `port`: extract from `docker-compose.yml` using the same grep pattern as current `list_sites()` (line 359): `grep -A 15 "nginx_$site:" "$COMPOSE_FILE" | grep -E '^\s*-\s*"[0-9]+:80"' | grep -oE '[0-9]+' | head -1`
   - `phpVersion`: extract from docker-compose.yml — `grep -A 3 "wp_$site:" "$COMPOSE_FILE" | grep "image:" | grep -oE 'php[0-9.]+' | sed 's/php//'`
   - `containerId`: `docker ps -q -f name="wp_$site" 2>/dev/null || true` (null if not running)
   - `localUrl`: `"http://localhost:$port"` if port found, null otherwise
   - `diskUsage`: `du -sh "$PROJECT_ROOT/wp_$site" 2>/dev/null | cut -f1 || null`

3. For services, collect these fixed entries:
   - Database: name="Database", check `wp_db` container, containerId via `docker ps -q -f name=wp_db`
   - Redis: name="Redis Cache", check `wp_redis` container
   - phpMyAdmin: name="phpMyAdmin", check `wp_phpmyadmin` container
   - PHPCS: name="PHP CodeSniffer", check `wp_phpcs` container
   - PHPStan: name="PHPStan", check `wp_phpstan` container
   - WP-CLI: name="WP-CLI", check `wp_cli` container
   Each service entry: `{ "name": "...", "status": "running"|"stopped", "containerId": "..."|null }`

4. Output the JSON using `printf` to build the JSON string. Use a jq-like approach or manual string building. Since jq may not be available, build JSON manually with careful escaping. Structure:
```json
{"success":true,"sites":[{...},{...}],"services":[{...},{...}]}
```

Use the `output_json()` helper to emit the final string.

5. In the `main()` function, modify the `"list"` case (line 1390) to check `JSON_OUTPUT`:
```bash
"list"|"ls")
    if [[ "$JSON_OUTPUT" == true ]]; then
        list_sites_json
    else
        list_sites "$@"
    fi
    ;;
```
</action>
<acceptance_criteria>
- `./matrix list --json` outputs valid JSON on stdout
- Output contains `"sites"` array and `"services"` array
- Each site entry has fields: name, status, port, phpVersion, containerId, localUrl, diskUsage
- Each service entry has fields: name, status, containerId
- `status` values are lowercase strings: "running" or "stopped"
- No ANSI color codes in the JSON output
- `./matrix list` (without --json) still produces the same human-readable table as before
- JSON parses cleanly with `./matrix list --json | python3 -m json.tool` (or similar)
</acceptance_criteria>
</task>

<task id="3">
<name>Add show_status_json() for matrix status --json</name>
<read_first>
- matrix (lines 482-494: show_status() — current implementation)
- matrix (lines 340-440: list_sites() for reference on container status checking)
</read_first>
<action>
Add a new function `show_status_json()` BEFORE `show_status()` (before line 482).

This function must:

1. Get the raw docker-compose ps output and parse it into structured JSON.

2. For each running container (from `$DOCKER_COMPOSE ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}"`), collect:
   - `name`: container name
   - `status`: container status string from docker
   - `ports`: exposed ports string

3. Add frontend status by checking if PID file exists and process is running:
   - `name`: "frontend"
   - `status`: "running" or "stopped"
   - `pid`: PID number or null
   - `url`: "http://localhost:8500" if running, null otherwise

4. Output JSON: `{"success":true,"containers":[{...}],"frontend":{...}}`

5. In `main()`, modify the `"status"` case (line 1381):
```bash
"status")
    if [[ "$JSON_OUTPUT" == true ]]; then
        show_status_json
    else
        show_status "$@"
    fi
    ;;
```
</action>
<acceptance_criteria>
- `./matrix status --json` outputs valid JSON on stdout
- JSON contains `"containers"` array with running container info
- JSON contains `"frontend"` object with running/stopped status
- No ANSI color codes in output
- `./matrix status` (without --json) still produces the same output as before
</acceptance_criteria>
</task>

<task id="4">
<name>Add show_info_json() for matrix info --json</name>
<read_first>
- matrix (lines 856-887: show_urls() — current "info" implementation, just shows URLs)
- matrix (lines 590-727: edit_site() — has code to extract PHP version and port from docker-compose.yml)
- matrix (lines 340-440: list_sites() — has code to check container status and get port)
</read_first>
<action>
Add a new function `show_info_json()` that provides comprehensive site details. Place it before `show_urls()`.

The function must accept a site name as `$1` and:

1. Validate site exists — if not, output `error_json "SITE_NOT_FOUND" "Site '$site_name' does not exist"`

2. Collect all available information:
   - `name`: site name
   - `status`: "running" or "stopped" (check via docker-compose ps)
   - `port`: extracted from docker-compose.yml (same grep pattern as list_sites)
   - `phpVersion`: extracted from docker-compose.yml image tag
   - `containerId`: docker ps -q -f name="wp_$site" (null if not running)
   - `localUrl`: "http://localhost:$port" if port found
   - `dbName`: "${site_name}_db"
   - `dbSize`: query from MySQL if db container is running — `docker exec wp_db mysql -u root -p"${MYSQL_ROOT_PASSWORD:-root}" -sN -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables WHERE table_schema='${site_name}_db'" 2>/dev/null || null`
   - `diskUsage`: `du -sh "$PROJECT_ROOT/wp_$site" 2>/dev/null | cut -f1`
   - `nginxConfigPath`: "config/nginx/$site_name.conf"
   - `wordpressVersion`: attempt to detect from `grep "wp_version =" "$PROJECT_ROOT/wp_$site_name/wp-includes/version.php" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || null`

3. Output JSON: `{"success":true,"site":{...}}`

4. In `main()`, modify the `"info"` case (line 1399):
```bash
"info")
    if [[ "$JSON_OUTPUT" == true ]]; then
        show_info_json "$@"
    else
        show_urls "$@"
    fi
    ;;
```

Note: The current `info` command just calls `show_urls()`. The non-JSON path keeps this behavior unchanged.
</action>
<acceptance_criteria>
- `./matrix info asgard --json` outputs valid JSON with all site details
- JSON includes fields: name, status, port, phpVersion, containerId, localUrl, dbName, dbSize, diskUsage, nginxConfigPath, wordpressVersion
- Running against a non-existent site outputs `{"success":false,"error":{"code":"SITE_NOT_FOUND","message":"..."}}` and exits with code 1
- `./matrix info asgard` (without --json) still shows URLs as before
</acceptance_criteria>
</task>

<task id="5">
<name>Add JSON output for matrix check --json</name>
<read_first>
- matrix (lines 730-811: run_checks() — current implementation)
</read_first>
<action>
Modify the `run_checks()` function to support JSON output mode. When `JSON_OUTPUT` is true:

1. Capture PHPCS stdout (not stderr) into a variable instead of letting it go directly to stdout.

2. Parse the PHPCS output to extract:
   - `filesScanned`: count of files from PHPCS output (look for "A total of" line or count FILE: references)
   - `errors`: array of `{file, line, message, severity}` — parse PHPCS error lines matching pattern `FILE:LINE:N:COLUMN: [type] message`
   - `warnings`: same structure for warnings
   - `totals`: `{ errors: N, warnings: N }`

3. If PHPCS fails or produces no parseable output, still output valid JSON with empty arrays.

4. For PHPStan (when a specific path is provided), same approach — capture output and parse into the same structure.

5. Output JSON:
```json
{
  "success": true,
  "results": [
    {
      "tool": "phpcs",
      "filesScanned": N,
      "errors": [...],
      "warnings": [...],
      "totals": { "errors": N, "warnings": N }
    },
    {
      "tool": "phpstan",
      "filesScanned": N,
      "errors": [...],
      "warnings": [...],
      "totals": { "errors": N, "warnings": N }
    }
  ]
}
```

Implementation approach: Wrap the existing `$DOCKER_COMPOSE --profile tools run` calls to capture stdout to a temp file when `JSON_OUTPUT` is true, then parse the temp file after the command completes. Use grep/sed/awk to extract structured data from the PHPCS and PHPStan text output formats.

The PHPCS output format for errors looks like:
```
FILE:LINE:N:COLUMN: [error] message
```

Parse with: `grep -E '^\s*\./' | while read line; do ... done`

For the non-JSON path, the existing behavior must be completely unchanged.
</action>
<acceptance_criteria>
- `./matrix check <site> --json` outputs valid JSON on stdout
- JSON contains `"results"` array with per-tool objects
- Each result has: tool, filesScanned, errors (array), warnings (array), totals
- PHPCS errors parsed from text output into structured format
- No ANSI color codes in output
- `./matrix check <site>` (without --json) still produces the same output as before
</acceptance_criteria>
</task>

<task id="6">
<name>Add Docker-unreachable error JSON handling</name>
<read_first>
- matrix (lines 34-42: docker-compose detection)
- matrix (lines 119-154: get_sites(), site_exists())
</read_first>
<action>
Add error handling so that when Docker is unreachable and `--json` is active, the CLI still outputs valid JSON instead of plain-text errors.

1. After the docker-compose detection block (after line 42), add a function `check_docker_json()`:
```bash
check_docker_json() {
    if [[ "$JSON_OUTPUT" == true ]]; then
        if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
            error_json "DOCKER_ERROR" "Docker/Podman is not installed or not in PATH"
        fi
        if ! docker info >/dev/null 2>&1; then
            error_json "DOCKER_ERROR" "Docker daemon is not running"
        fi
    fi
}
```

2. Call `check_docker_json` at the beginning of `list_sites_json()`, `show_status_json()`, and `show_info_json()` — right at the top of each function, before any docker commands.

3. In `error_json()`, ensure the exit code is 1 (already done in task 1, but verify).

4. Wrap any `$DOCKER_COMPOSE ps` calls inside the JSON functions with error handling:
```bash
local compose_output
compose_output=$($DOCKER_COMPOSE ps 2>&1) || {
    error_json "DOCKER_ERROR" "Failed to query Docker Compose: $compose_output"
}
```

This ensures that even if Docker goes down mid-execution, the JSON output is valid.
</action>
<acceptance_criteria>
- With Docker stopped, `./matrix list --json` outputs `{"success":false,"error":{"code":"DOCKER_ERROR","message":"..."}}` (not a plain-text error)
- The command exits with non-zero status code
- The JSON is valid and parseable
- `./matrix list` (without --json) with Docker stopped still shows the plain-text error as before
</acceptance_criteria>
</task>

## Verification
1. Run `./matrix list --json | python3 -m json.tool` — valid JSON with sites and services arrays
2. Run `./matrix status --json | python3 -m json.tool` — valid JSON with containers and frontend
3. Run `./matrix info <existing-site> --json | python3 -m json.tool` — valid JSON with all site details
4. Run `./matrix info nonexistent --json` — outputs error JSON with SITE_NOT_FOUND code
5. Run `./matrix list` (no --json) — identical output to before changes
6. Run `./matrix status` (no --json) — identical output to before changes
7. Stop Docker, run `./matrix list --json` — outputs DOCKER_ERROR JSON
