---
phase: 01
plan: 02
wave: 2
depends_on: [01]
requirements: [API-02, API-03, API-04]
files_modified: [frontend/app.js, frontend/public/js/app.js, frontend/views/dashboard.handlebars]
autonomous: true
---

# Plan 02: Refactor Frontend to Use Structured JSON

## Objective
Replace the fragile `parseSiteList()` text-parsing function with direct `JSON.parse()` of CLI output. Update all API endpoints to pass `--json` to read commands. Add input validation and structured error responses with HTTP status code mapping.

## must_haves
- `parseSiteList()` removed entirely, replaced with `JSON.parse()`
- All API routes for read operations pass `--json` to matrix
- Error responses include `{ code, message }` structure
- HTTP status codes map from CLI error codes (404, 400, 409, 503)
- Input validation rejects invalid site names, actions, and PHP versions
- Dashboard renders correctly with new data format

<task id="1">
<name>Replace parseSiteList with JSON parsing and update executeMatrix</name>
<read_first>
- frontend/app.js (full file, 290 lines)
- .planning/phases/01-structured-api-layer/01-CONTEXT.md (decisions section)
</read_first>
<action>
1. In `frontend/app.js`, add a constant after the require statements (around line 10):
```javascript
const SUPPORTED_PHP_VERSIONS = ['7.4', '8.0', '8.1', '8.2', '8.3'];
```

2. Modify the `executeMatrix()` function (lines 30-78):
   - Add a second parameter `jsonMode = false`:
     ```javascript
     const executeMatrix = async (command, args = [], jsonMode = false) => {
     ```
   - When `jsonMode` is true, prepend `--json` to the args array BEFORE the command. The spawn call becomes:
     ```javascript
     const spawnArgs = jsonMode ? [command, '--json', ...args] : [command, ...args];
     const matrixCmd = spawn(matrixPath, spawnArgs, {
     ```
   - After the `matrixCmd.on('close')` handler resolves, add JSON parsing for jsonMode. Modify the close handler:
     ```javascript
     matrixCmd.on('close', (code) => {
       console.log(`[Frontend] Command completed with code: ${code}`);
       if (jsonMode && code === 0) {
         try {
           const jsonData = JSON.parse(stdout);
           resolve({ success: true, data: jsonData, stdout, stderr });
         } catch (e) {
           console.error(`[Frontend] JSON parse error:`, e);
           resolve({ success: false, stdout, stderr, exitCode: code, error: 'Invalid JSON from CLI' });
         }
       } else if (jsonMode && code !== 0) {
         try {
           const errData = JSON.parse(stdout);
           resolve({ success: false, data: errData, stdout, stderr, exitCode: code });
         } catch (e) {
           resolve({ success: false, stdout, stderr, exitCode: code });
         }
       } else if (code === 0) {
         resolve({ success: true, stdout, stderr });
       } else {
         resolve({ success: false, stdout, stderr, exitCode: code });
       }
     });
     ```

3. Delete the `parseSiteList()` function entirely (lines 81-123).

4. Update the `GET /` route (lines 126-143):
   - Change `executeMatrix('list')` to `executeMatrix('list', [], true)`
   - Change `const { sites, services } = parseSiteList(result.stdout)` to `const { sites, services } = result.data || { sites: [], services: [] }`
   - The render call stays the same shape.

5. Update the `GET /api/sites` route (lines 145-162):
   - Change `executeMatrix('list')` to `executeMatrix('list', [], true)`
   - Change `const { sites, services } = parseSiteList(result.stdout)` to use `result.data`
   - Remove the `raw: result.stdout` field (no longer needed since data is structured)

6. Update the `GET /api/status` route (lines 248-262):
   - Change `executeMatrix('status')` to `executeMatrix('status', [], true)`
   - Use `result.data` for the response body instead of `result.stdout`
</action>
<acceptance_criteria>
- `parseSiteList` function does not exist anywhere in frontend/app.js
- `executeMatrix` accepts a third `jsonMode` parameter
- When jsonMode is true, `--json` is included in the spawn arguments
- When jsonMode is true and exit code is 0, result.data contains the parsed JSON object
- `GET /` route passes jsonMode=true for list command
- `GET /api/sites` route passes jsonMode=true for list command
- `GET /api/status` route passes jsonMode=true for status command
</acceptance_criteria>
</task>

<task id="2">
<name>Add input validation and structured error responses</name>
<read_first>
- frontend/app.js (lines 164-246: POST route handlers)
- .planning/phases/01-structured-api-layer/01-CONTEXT.md (Error Handling decisions)
</read_first>
<action>
1. Add a validation helper function after the executeMatrix function (where parseSiteList used to be):
```javascript
const VALID_SITE_NAME = /^[a-zA-Z][a-zA-Z0-9_-]*$/;
const RESERVED_NAMES = ['frontend', 'matrix', 'db', 'redis', 'phpmyadmin', 'nginx'];
const VALID_SITE_ACTIONS = ['create', 'start', 'stop', 'remove', 'info', 'url'];
const VALID_ENV_ACTIONS = ['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check'];

const validateSiteName = (name) => {
  if (!name || typeof name !== 'string') return { valid: false, code: 'INVALID_NAME', message: 'Site name is required' };
  if (!VALID_SITE_NAME.test(name)) return { valid: false, code: 'INVALID_NAME', message: 'Site name must start with a letter and contain only alphanumeric characters, hyphens, and underscores' };
  if (RESERVED_NAMES.includes(name.toLowerCase())) return { valid: false, code: 'INVALID_NAME', message: `"${name}" is a reserved name` };
  return { valid: true };
};

const ERROR_STATUS_MAP = {
  SITE_NOT_FOUND: 404,
  SITE_ALREADY_EXISTS: 409,
  INVALID_NAME: 400,
  DOCKER_ERROR: 503,
  COMMAND_FAILED: 500,
};

const sendError = (res, code, message, overrideStatus) => {
  const status = overrideStatus || ERROR_STATUS_MAP[code] || 500;
  res.status(status).json({ success: false, error: { code, message } });
};
```

2. Update the `POST /api/sites/:action` route (lines 164-191):
   - Replace the existing validation block with:
     ```javascript
     const { action } = req.params;
     const { siteName, phpVersion } = req.body;
     
     if (!VALID_SITE_ACTIONS.includes(action)) {
       return sendError(res, 'INVALID_NAME', `Invalid action: ${action}`, 400);
     }
     
     if (siteName) {
       const validation = validateSiteName(siteName);
       if (!validation.valid) {
         return sendError(res, validation.code, validation.message);
       }
     } else if (['create', 'start', 'stop', 'remove', 'info', 'url'].includes(action)) {
       return sendError(res, 'INVALID_NAME', 'Site name is required', 400);
     }
     
     if (phpVersion && !SUPPORTED_PHP_VERSIONS.includes(phpVersion)) {
       return sendError(res, 'INVALID_NAME', `Invalid PHP version: ${phpVersion}. Supported: ${SUPPORTED_PHP_VERSIONS.join(', ')}`, 400);
     }
     ```
   - For the create action, build args with phpVersion:
     ```javascript
     let args;
     if (action === 'create') {
       args = phpVersion ? [siteName, `--php-version=${phpVersion}`] : [siteName];
     } else if (action === 'remove') {
       args = [siteName, '--yes'];
     } else {
       args = [siteName];
     }
     ```
   - For actions that support JSON (info), use jsonMode:
     ```javascript
     const useJson = ['info'].includes(action);
     const result = await executeMatrix(action, args, useJson);
     ```
   - For the response, check if result has structured error data:
     ```javascript
     if (!result.success) {
       if (result.data && result.data.error) {
         return sendError(res, result.data.error.code, result.data.error.message);
       }
       return sendError(res, 'COMMAND_FAILED', result.stderr || 'Command failed');
     }
     
     const response = { success: true };
     if (useJson && result.data) {
       response.data = result.data;
     } else {
       response.output = result.stdout;
     }
     res.json(response);
     ```

3. Update the `POST /api/environment/:action` route (lines 193-218):
   - Change the validation to:
     ```javascript
     if (!VALID_ENV_ACTIONS.includes(action)) {
       return sendError(res, 'INVALID_NAME', `Invalid action: ${action}`, 400);
     }
     ```
   - Use sendError for catch block:
     ```javascript
     } catch (error) {
       sendError(res, 'COMMAND_FAILED', error.message);
     }
     ```

4. Update the `POST /api/frontend/:action` route (lines 220-246):
   - Same pattern: validate action, use sendError.

5. Update all `res.status(500).json({ success: false, error: ... })` catch blocks to use `sendError(res, 'COMMAND_FAILED', error.message)`.

6. Update the `GET /api/sites` error handler:
   ```javascript
   } catch (error) {
     sendError(res, 'COMMAND_FAILED', error.message);
   }
   ```

7. Update the `GET /api/status` route to use structured data:
   ```javascript
   res.json({
     success: true,
     data: result.data || null,
     output: result.data ? undefined : result.stdout
   });
   ```
</action>
<acceptance_criteria>
- `validateSiteName` function exists and returns `{ valid: true }` or `{ valid: false, code, message }`
- `sendError` function exists and maps error codes to HTTP status codes
- `POST /api/sites/create` with invalid site name returns 400 with `{ error: { code: 'INVALID_NAME', message: '...' } }`
- `POST /api/sites/create` accepts `phpVersion` in body, rejects unsupported versions with 400
- `POST /api/sites/:action` rejects unknown actions with 400
- `POST /api/environment/:action` rejects unknown actions with 400
- All catch blocks use `sendError` with `COMMAND_FAILED` code
- `GET /api/sites` returns `{ success: true, sites: [...], services: [...] }` from parsed JSON
</acceptance_criteria>
</task>

<task id="3">
<name>Update client-side JS and Handlebars templates for new data shape</name>
<read_first>
- frontend/public/js/app.js (full file, 351 lines)
- frontend/views/dashboard.handlebars (full file, 234 lines)
</read_first>
<action>
1. Review the current site data fields used in `frontend/public/js/app.js`:
   - `updateDashboard()` at line 78-88 filters by `site.status === 'Running'` and `service.status === 'Running'` — these field names match the new JSON output, so no change needed.
   - `currentData.sites` and `currentData.services` — same shape, no change needed.

2. Review `frontend/views/dashboard.handlebars`:
   - The template uses Handlebars `{{#each sites}}` and `{{#each services}}` — verify these still work with the new JSON shape.
   - Check each `{{name}}`, `{{status}}`, `{{localUrl}}`, `{{domainUrl}}` reference. The new JSON uses `localUrl` (with camelCase). The CLI's current text output uses columns "Local URL" and "Domain URL" which `parseSiteList` mapped to `localUrl` and `domainUrl`.
   - New JSON fields: `name`, `status`, `port`, `phpVersion`, `containerId`, `localUrl`, `diskUsage` for sites.
   - New JSON fields for services: `name`, `status`, `containerId`.
   - The template currently shows `{{localUrl}}` and `{{domainUrl}}` — `domainUrl` will no longer exist in the JSON (the CLI only produces `localUrl`). Update any references to `{{domainUrl}}` to remove them or replace with something useful like the PHP version.
   
3. In `dashboard.handlebars`, find the site card template (search for `domainUrl`). Replace:
   - Any `{{domainUrl}}` references: change to `{{phpVersion}}` display or remove the column.
   - Specifically, the site card table row that shows "Domain URL" should show "PHP" version instead:
     Change from showing `{{domainUrl}}` to showing `PHP {{phpVersion}}` if the site has a phpVersion field.

4. In `dashboard.handlebars`, the services table similarly references fields. Verify the service entries still render correctly with `name` and `status` fields (they should, since the new JSON uses the same field names).

5. In `frontend/public/js/app.js`:
   - `siteAction()` function (line 119): Currently shows `data.error` in the notification. The new API returns `data.error.message` (structured). Update:
     ```javascript
     const errorMsg = data.error?.message || data.error || 'Unknown error';
     showNotification(`Command "${action} ${siteName}" failed: ${errorMsg}`, 'danger');
     ```
   - `quickAction()` function (line 91): Same update for error message display.
   - `createSite()` function (line 154): Same update. Also add `phpVersion` to the request body:
     ```javascript
     const phpVersionSelect = document.getElementById('phpVersion');
     const phpVersion = phpVersionSelect ? phpVersionSelect.value : undefined;
     body: JSON.stringify({ siteName, ...(phpVersion && { phpVersion }) })
     ```
   - `loadDashboard()` function (line 58): The response shape changes from `{ success, sites, services, raw }` to `{ success, sites, services }` — no `raw` field. Verify `currentData = data` still captures sites and services correctly. It does since the top-level shape is the same.

6. If `dashboard.handlebars` has a PHP version dropdown or selector for site creation, verify it sends `phpVersion` in the create request. If no selector exists, the `createSite()` JS function should default to not sending phpVersion (CLI defaults to 8.3).
</action>
<acceptance_criteria>
- `frontend/public/js/app.js` references `data.error?.message || data.error` for error display (not just `data.error`)
- No references to `domainUrl` in any Handlebars template or JS file
- Site cards show `PHP {{phpVersion}}` (or equivalent) instead of domain URL
- `createSite()` sends `phpVersion` in request body if a PHP version selector exists
- Dashboard loads and renders correctly with new JSON data format
- Site status badges still show "Running" / "Stopped" correctly
- Error notifications display the structured error message
</acceptance_criteria>
</task>

## Verification
1. Start the frontend: `cd frontend && npm start`
2. Open `http://localhost:8500` — dashboard renders with site cards showing correct data
3. `curl http://localhost:8500/api/sites | python3 -m json.tool` — returns `{ success: true, sites: [...], services: [...] }` with structured fields
4. `curl -X POST http://localhost:8500/api/sites/create -H 'Content-Type: application/json' -d '{"siteName":"test-invalid-name-"}' | python3 -m json.tool` — wait, that name is actually valid. Test with `{"siteName":"123"}` — should return 400 with INVALID_NAME
5. `curl -X POST http://localhost:8500/api/sites/create -H 'Content-Type: application/json' -d '{"siteName":"ok","phpVersion":"5.6"}' | python3 -m json.tool` — returns 400 with INVALID_NAME for bad PHP version
6. `curl -X POST http://localhost:8500/api/sites/nonexistent-action -H 'Content-Type: application/json' -d '{"siteName":"foo"}' | python3 -m json.tool` — returns 400
7. Click Refresh on dashboard — data reloads correctly
8. Click Start/Stop on a site — operation succeeds, dashboard refreshes
9. Verify no `parseSiteList` references exist: `grep -r parseSiteList frontend/`
