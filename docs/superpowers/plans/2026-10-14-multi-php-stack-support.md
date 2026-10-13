# Multi-PHP-stack site support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `./matrix create <name> --type=<wp|laravel|symfony|drupal|joomla|grav>` provisions and starts sites of those types; `wp` default keeps today's behavior byte-for-byte.

**Architecture:** New `scripts/site-types-lib.sh` holds the type registry and per-type provisioning, sourced and dispatched from `matrix` (repo convention: matrix stops holding domain logic). `compose_add_site` grows a type param choosing image/env; nginx heredocs get a type-aware webroot. Composer provisioning runs one-shot `matrix-php:<ver>` (composer baked in), not `composer:2`.

**Tech Stack:** Bash (repo style), Docker/Podman via `$CONTAINER_RUNTIME`, PHP official fpm images, stub-based offline bash tests, Jest for frontend.

**Spec:** `docs/superpowers/specs/2026-10-13-multi-php-stack-support-design.md` (read with this plan; builder-check decisions are settled there).

## Global Constraints

- Type set exactly: `wp laravel symfony drupal joomla grav`. PHP floors: wp 7.4, joomla 8.1, grav 8.1, laravel 8.2, symfony 8.2, drupal 8.3.
- Webroots: wp/joomla/grav → `/var/www/html`; laravel/symfony → `/var/www/html/public`; drupal → `/var/www/html/web`.
- Type persisted at `wp_<site>/.matrix-type`; missing file ⇒ `wp` (existing sites unaffected).
- Non-wp runtime image name: `matrix-php:<php_version>` (Dockerfile at `config/docker/php-site/Dockerfile`, composer + unzip baked in).
- grav = no database anywhere (no DB create, no compose `depends_on`, no env seeding, no db in export/import).
- Config seeding: laravel → patch generated `.env` keys (`DB_HOST=db`, `DB_DATABASE=<site>_db`, `DB_USERNAME=${MYSQL_USER:-wp_user}`, `DB_PASSWORD=${MYSQL_PASSWORD:-wp_password}`), never overwrite; symfony → set `DATABASE_URL="mysql://user:pass@db:3306/<site>_db"` in `.env`; drupal → write `web/sites/default/settings.php` with DB creds + `hash_salt` before first visit; joomla → nothing (creds printed by create).
- Rollback on non-wp provisioning failure: remove site dir + compose entry, error exit. WP path keeps best-effort.
- Repo test rules (from docs/TDD-IMPLEMENTATION.md + memory): never commit a red suite; stubs only at container/sudo/curl boundaries; suites must reach the production path; each suite <10s; new suites source `scripts/*-lib.sh` directly, never source `matrix` wholesale unless using the multisite-test reset pattern (`set +e`, sandbox `PROJECT_ROOT`, re-export `run_wp_cli`).
- Release bar (final task): `bash -n matrix scripts/*.sh`, all suites in `tests/bash/{site-state,stubs,ssl,multisite,presets,doctor,wp-version,export-import,share,ops,site-types}-test.sh` green, `npm --prefix frontend test`, `./matrix list --json | python3 -m json.tool`, `scripts/health-check.sh`.
- No repo/CLI rename in this work. Apache stack stays WP-only.

## Review Focus

Live failure modes the stub tests can't fully prove, most likely first:
1. Composer/network failure mid-create leaves a half-site → expect rollback, no `wp_<name>` dir, no compose entry. (Pinned: Task 8, T1.)
2. Pre-existing WP sites (no `.matrix-type`) after upgrade → expect identical behavior everywhere. (Pinned: Task 1, T2.)
3. `--type x` space form parsing like other flags → expect same handling as `--stack x`. (Pinned: Task 5, T1.)
4. `grav` export then import round-trip → expect bundle without `db/` member, import restores files only. (Pinned: Task 11, T1.)
5. Type/floor mismatch (`--type=drupal --php-version=8.1`) → expect clear error naming floor, no dir created. (Pinned: Task 5, T4.)

---

### Task 1: Type registry (`scripts/site-types-lib.sh`)

**Files:**
- Create: `scripts/site-types-lib.sh`
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Produces (later tasks consume):
  - `validate_site_type <type>` → rc 0/1
  - `site_type_min_php <type>` → echoes `7.4|8.1|8.2|8.3`
  - `site_type_webroot <type>` → echoes ``|`public`|`web` (relative to `/var/www/html`)
  - `site_type_uses_db <type>` → rc 0=yes/1=no (only grav = no)
  - `site_type_runtime_image <type> <php>` → echoes `wordpress:php<php>-fpm` or `matrix-php:<php>`
  - `get_site_type <site>` → echoes contents of `$PROJECT_ROOT/wp_<site>/.matrix-type`, `wp` when file missing
  - `set_site_type <site> <type>` → writes the file
  - `php_at_least <have> <floor>` → rc 0 when have >= floor (compare via `sort -V`)

- [ ] **Step 1: Write failing test** `tests/bash/site-types-test.sh`, following `ssl-test.sh` structure (source `scripts/site-types-lib.sh` + `scripts/helpers.sh`, stub `log_*`). Cases:
  - `validate_site_type laravel` ok; `validate_site_type magento` fails; `validate_site_type ""` fails.
  - `site_type_min_php drupal` = `8.3`; `site_type_min_php wp` = `7.4`.
  - `site_type_webroot laravel` = `public`; `drupal` = `web`; `wp` = empty.
  - `site_type_uses_db grav` rc 1; `laravel` rc 0.
  - `site_type_runtime_image wp 8.3` = `wordpress:php8.3-fpm`; `laravel 8.2` = `matrix-php:8.2`.
  - `get_site_type` on sandbox site without file = `wp`; with file `drupal` = `drupal` (uses a `$SANDBOX/wp_t1` dir, `PROJECT_ROOT` overridden to sandbox — see note).
  - `php_at_least 8.1 8.2` rc 1; `8.3 8.2` rc 0; `7.4 7.4` rc 0.
- [ ] **Step 2: Run** `bash tests/bash/site-types-test.sh` → expect FAIL (lib missing).
- [ ] **Step 3: Implement** the functions above in `scripts/site-types-lib.sh`. Sandbox note: `get_site_type`/`set_site_type` read `$PROJECT_ROOT`, and `site-types-test.sh` sets `PROJECT_ROOT="$SANDBOX"` before invoking.
- [ ] **Step 4: Run** → PASS. Also `bash -n scripts/site-types-lib.sh`.
- [ ] **Step 5: Commit** `feat: site-type registry lib (types, floors, webroots, image picker)`

### Task 2: `matrix-php` Dockerfile + build wiring

**Files:**
- Create: `config/docker/php-site/Dockerfile`
- Modify: `scripts/site-types-lib.sh` (add `build_site_image <php>`)
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Produces: `build_site_image <php_version>` — builds `matrix-php:<ver>` only if `$CONTAINER_RUNTIME images -q matrix-php:<ver>` is empty; runs `docker build --build-arg PHP_VERSION=<ver> -t matrix-php:<ver> config/docker/php-site`. Test stubs `$CONTAINER_RUNTIME`.

- [ ] **Step 1: Failing test** — with docker stub (`tests/bash/bin/docker`): first `build_site_image 8.3` records a `build --build-arg PHP_VERSION=8.3` call; second call records none (image exists).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Dockerfile: `ARG PHP_VERSION=8.3`, `FROM php:${PHP_VERSION}-fpm`, apt `libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libicu-dev unzip`, `docker-php-ext-install gd intl zip bcmath pdo_mysql`, composer installer to `/usr/local/bin/composer`.
- [ ] **Step 4: Run** → PASS. `bash -n` on lib.
- [ ] **Step 5: Commit** `feat: matrix-php runtime image (composer+unzip baked in)`

### Task 3: `compose_add_site` type param

**Files:**
- Modify: `scripts/compose-lib.sh:42` (`compose_add_site` gains 6th arg `type="${6:-wp}"`)
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Consumes: `site_type_runtime_image`, `site_type_uses_db`.
- Produces: `compose_add_site <site> <php> <port> <nginx_conf> <stack> <type>`. wp = unchanged output (image `wordpress:php<ver>-fpm`, `WORDPRESS_DB_*` env, `depends_on: db`). non-wp = image from registry, **no** `WORDPRESS_DB_*` env, keeps `depends_on: db` except grav drops the `depends_on` block.

- [ ] **Step 1: Failing tests** (compose stub file, reuse `site-state-test.sh` harness style): for each type assert the generated `wp_<site>:` service block contains expected image string; `grep -c WORDPRESS_DB_HOST` = 1 for wp, 0 for laravel; grav block has no `depends_on`; laravel block has `depends_on`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** — replace the fixed `image:`/env lines in the heredoc with registry lookups; wrap `depends_on` in an `if uses_db` heredoc fragment.
- [ ] **Step 4: Run suite** → PASS, and `bash tests/bash/site-state-test.sh` still PASS (wp path unchanged).
- [ ] **Step 5: Commit** `feat: compose_add_site type-aware image/env/depends_on`

### Task 4: Type-aware nginx webroot

**Files:**
- Modify: `matrix` heredocs at lines 379, 1904, 2790, 2858, 2932; `scripts/common.sh:100` — each `root /var/www/html;` → `root /var/www/html${webroot};` with `local webroot; webroot=$(site_type_webroot "$type")` available in each enclosing function (thread `type` into the enclosing function's params where it isn't already).
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Consumes: `site_type_webroot`.
- Produces: `generate_nginx_conf <site> <type>` helper in `matrix` replacing the inline heredoc at line 368-404 (`create_site` calls it); other 5 heredocs (apache/ssl/repair paths) get the same `${webroot}` substitution using `get_site_type`.

- [ ] **Step 1: Failing test** — call `generate_nginx_conf laravel_site laravel` with `$PROJECT_ROOT` sandboxed; assert conf file contains `root /var/www/html/public;` and `fastcgi_pass laravel_site:9000`. `wp` case asserts `root /var/www/html;` unchanged.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `generate_nginx_conf` (extract of current heredoc, one `${webroot}` on the root line, plus `client_max_body_size 25m;` per spec) and patch the other 5 heredocs' root lines.
- [ ] **Step 4: Run** `site-types` + `ssl` suites → PASS.
- [ ] **Step 5: Commit** `feat: per-type nginx webroot (public/ for laravel+symfony, web/ for drupal)`

### Task 5: `create_site --type` parsing, validation, flags

**Files:**
- Modify: `matrix` `create_site()` (lines 203-330): new `--type`/`--type=` options; `--wp-version` and `--multisite` rejected when type != wp; php floor enforcement; `.matrix-type` written after dir creation.
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Consumes: all Task 1 functions.
- Produces: `create_site` understands `type` local; usage line updated: `[--type=wp|laravel|symfony|drupal|joomla|grav]`.

- [ ] **Step 1: Failing tests** (matrix-source reset pattern per memory: `set +e`, sandbox `PROJECT_ROOT`, re-export `run_wp_cli`; docker + compose stubs):
  - `create_site t1 --type=laravel --skip-download` writes `.matrix-type` = `laravel` (provisioning will be stubbed later tasks; here stub `provision_site_type` — declare function before sourcing? No: matrix sources site-types-lib, so define a failing provision stub via `export -f` AFTER sourcing matrix, before calling `create_site`).
  - `create_site t2 --type=drupal --php-version=8.1` fails with error containing `PHP 8.3` and creates no dir.
  - `create_site t3 --type=laravel --wp-version=6.4` fails with `only supported for wp`.
  - `create_site t4 --type magento` fails listing valid types.
  - `create_site t5 --skip-download` (no flag) writes `.matrix-type` = `wp`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** option parsing (mirror `--stack`), `validate_site_type`, `php_at_least "$php_version" "$(site_type_min_php "$type")"` → error `"$type requires PHP >= floor"`, wp-only-flag guard, `set_site_type` after `mkdir`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: create_site --type flag with validation and floors`

### Task 6: Composer provisioning (laravel, symfony) + post-start key gen

**Files:**
- Modify: `scripts/site-types-lib.sh` (add `provision_composer <site> <type>`, `seed_laravel_env <site>`, `seed_symfony_env <site>`)
- Modify: `matrix` `create_site` — non-wp types call `provision_site_type` (dispatcher added in Task 7 covers all; here wire laravel/symfony branches)
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Produces:
  - `provision_composer <site> <type> <php>`: runs `$CONTAINER_RUNTIME run --rm -v "$PROJECT_ROOT/wp_<site>":/var/www/html matrix-php:<php> composer create-project --no-interaction ...` — exact commands: laravel → `composer create-project laravel/laravel /var/www/html --no-interaction --prefer-dist`; symfony → `composer create-project symfony/skeleton /var/www/html --no-interaction`; then chown www-data; then the seeder. On any failure → return 1 (rollback is Task 8's). Note: `create-project laravel/laravel` already generates `.env` with `APP_KEY`; the seeder only patches the 4 DB keys, and `php artisan key:generate --force` runs post-start ONLY if `APP_KEY=` is still empty (guard in the laravel branch of create's post-start section, next to `apply_performance_tweaks`).
  - `seed_laravel_env <site>`: in-place sed patch of generated `.env` for the 4 DB keys (idempotent: skip key if already `db`).
  - `seed_symfony_env <site>`: append/replace `DATABASE_URL=...` line in `.env`.

- [ ] **Step 1: Failing tests** (docker stub records `run` args; sandbox): laravel create → recorded args contain `composer create-project laravel/laravel`; `.env` in sandbox site dir contains `DB_HOST=db`, `DB_DATABASE=laravel_site_db`; symfony → `.env` contains `DATABASE_URL="mysql://wp_user:wp_password@db:3306/symf_site_db"`; re-running seeder does not duplicate lines (idempotency).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: composer provisioning for laravel+symfony with env seeding`

### Task 7: Joomla zip + grav + `provision_site_type` dispatcher

**Files:**
- Modify: `scripts/site-types-lib.sh` (`provision_site_type <site> <type> <php>` dispatches: wp → existing inline flow is NOT moved (still in create_site); laravel/symfony → `provision_composer`; drupal → `provision_composer` + `seed_drupal_settings`; joomla → `provision_joomla`; grav → `provision_composer` variant with `getgrav/grav`)
- Modify: `matrix` `create_site` — type != wp branch calls `provision_site_type` before compose/db/nginx steps; db-create step wrapped in `site_type_uses_db` guard.
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Produces:
  - `JOOMLA_ZIP_URL` (readonly, `MATRIX_JOOMLA_URL` overridable, default floating Joomla 5 stable full-package zip from downloads.joomla.org).
  - `provision_joomla <site> <php>`: one-shot `matrix-php` container: `curl -fsSL "$JOOMLA_ZIP_URL" -o /tmp/j.zip && unzip -q /tmp/j.zip -d /var/www/html && chown -R www-data:www-data /var/www/html`.
  - `seed_drupal_settings <site>`: writes `web/sites/default/settings.php` (`$databases['default']['default']` array with `mysql`, db `web_<x>_db`... exact: database `<site>_db`, username/password from env, host `db`; plus `$settings['hash_salt']` from `head -c 32 /dev/urandom | base64`), plus `chmod 444` semantics not needed (wizard requires settings absent or configured — configured is fine).
  - grav path: `composer create-project getgrav/grav /var/www/html --no-interaction`; no env seeding.
- Task 6 note: symfony uses `DATABASE_URL` (composer project generates that name), laravel uses `DB_*` — verified against both projects' generated `.env`.

- [ ] **Step 1: Failing tests**: joomla → recorded docker run contains `downloads.joomla.org` and `unzip`, and create output prints the DB creds (`<site>_db`); drupal → `web/sites/default/settings.php` exists with `<site>_db` and `hash_salt`; grav → create-project string contains `getgrav/grav` and no `.env` written; `create_site grav_site --type=grav --skip-download`-style sandbox run records **no** `mysql` exec (db guard) while laravel run does.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: joomla zip + grav composer + drupal settings seeding + type dispatcher`

### Task 8: Rollback on non-wp provisioning failure

**Files:**
- Modify: `matrix` `create_site` — non-wp branch: `if ! provision_site_type ...; then rollback_site_create; return 1; fi` placed AFTER dir creation, BEFORE compose_add_site? No: compose entry is added before db step today (line 411-418). Reorder minimally: run provisioning first, then compose/db/nginx so rollback only ever removes the dir.
- Modify: `scripts/site-types-lib.sh` (`rollback_site_create <site>` → `rm -rf "$PROJECT_ROOT/wp_<site>"` + log).
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Produces: `rollback_site_create <site>`; non-wp create order = validate → mkdir/.matrix-type → provision → compose → db → nginx → start.

- [ ] **Step 1: Failing test**: make composer stub fail (exit 1) for `laravel` → `create_site` returns 1, sandbox `wp_lsite` dir absent, recorded compose stub shows NO `compose_add_site` write for lsite. wp path regression: existing `--skip-download` flow still adds compose entry (pin with one case).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** reorder + guard.
- [ ] **Step 4: Run suite → PASS; `bash -n matrix`.
- [ ] **Step 5: Commit** `feat: rollback failed non-wp provisioning (no half-sites)`

### Task 9: WP-only command gating

**Files:**
- Modify: `scripts/site-types-lib.sh` (`require_site_type <site> <allowed-types...>` → error `not supported for <type>` + rc 1, listing supported types when violated)
- Modify: `matrix` dispatch sites: `wp` command (`matrix:3280`), `test`/compat (cmd_test), `update-core`, `search-replace`, `cache-clear`, `optimize`, and `apply_preset` call in create (preset + type ≠ wp → same error at flag-parse time).
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Consumes: `get_site_type`.
- Produces: `require_site_type <site> <allowed-type>` → rc 0 when `get_site_type <site>` = allowed-type, else error string exact: `"command not supported for <type> site (requires wp)"` + rc 1.

- [ ] **Step 1: Failing tests**: sandbox laravel site → `matrix wp lsite core version` path errors with exact string; same for `optimize`, `test`, `update-core`, `search-replace`, `cache-clear` (call the dispatch-level guard functions or cmd wrappers with stubbed bodies as needed — assert the guard, not the whole command); `create_site --type=laravel --preset=woocommerce` errors at parse.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** guards at each dispatch site.
- [ ] **Step 4: Run** → PASS; suites `presets`, `wp-version`, `ops` still PASS (wp sites unaffected).
- [ ] **Step 5: Commit** `feat: gate wp-only commands with require_site_type`

### Task 10: clone + reset type-aware

**Files:**
- Modify: `scripts/clone.sh` — after `cp -R` (which already copies `.matrix-type`): skip wp-config sed when `get_site_type "$NEW_SITE"` != wp; skip create-db/import/search-replace entirely for grav; URL search-replace runs only for wp.
- Modify: `scripts/reset.sh` — reset re-runs create with the site's own type and php: `--type "$(get_site_type "$name")"`.
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Consumes: `get_site_type`, `site_type_uses_db`.

- [ ] **Step 1: Failing tests**: clone stub run for grav source → no `mysqldump` recorded; clone of laravel source → no `wp-config.php` sed recorded, DB created; reset of laravel site calls create with `--type laravel`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat: type-aware clone and reset`

### Task 11: export/import grav (no db) + `type` in site_state/info

**Files:**
- Modify: `scripts/export-import-lib.sh` — `export_site`: when `site_type_uses_db "$(get_site_type "$site")"` fails, skip `dump_site_db`/db member; manifest gains `"type"` and omits `db_dump_sha256` for grav. `import_site`: db restore step guarded the same way (manifest-driven: no db key → skip).
- Modify: `scripts/helpers.sh` `site_state` (line 169) — gains `type=$(get_site_type "$site")` line.
- Test: `tests/bash/site-types-test.sh`

**Interfaces:**
- Consumes: `get_site_type`, `site_type_uses_db`.

- [ ] **Step 1: Failing tests**: export stub run for grav site → no `mysqldump` recorded, manifest JSON contains `"type": "grav"` and no `db_dump_sha256`; import of such a manifest → no `mysql` import recorded, files restored; `site_state` output contains `type=grav` for grav sandbox site and `type=wp` for dir without marker.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run suite + `export-import-test.sh`** → PASS.
- [ ] **Step 5: Commit** `feat: grav export/import without db; type in site_state`

### Task 12: Dashboard — create-modal type select + type badge

**Files:**
- Modify: `frontend/app.js` — `/api/sites/create` accepts+validates `type` against the same 6-value whitelist (mirror existing validators); passes `--type=<type>` to matrix args.
- Modify: `frontend/views/dashboard.handlebars` — create modal gains Type select (6 options, wp default); site card + flyout show type badge from `/api/sites` payload (`type` key comes from `matrix list --json` via site_state).
- Test: `frontend/__tests__/app.test.js`

**Interfaces:**
- Consumes: `create_site --type`, `site_state type=`.

- [ ] **Step 1: Failing Jest tests**: POST `/api/sites/create` with `type: "laravel"` spawns matrix with `--type=laravel`; `type: "magento"` → 400 with validation message; omitted type → no `--type` arg (wp default).
- [ ] **Step 2: Run** `npm --prefix frontend test` → FAIL.
- [ ] **Step 3: Implement** validator + flag passthrough + handlebars select/badge.
- [ ] **Step 4: Run** → PASS (37 existing + new).
- [ ] **Step 5: Commit** `feat: dashboard type select and badges`

### Task 13: Docs + release bar

**Files:**
- Modify: `AGENTS.md` (create command reference gains `--type`, new suite in verified bar, dashboard create-modal note), `README.md` (feature table row: multi-PHP-stack, command reference line).

- [ ] **Step 1: Update both docs** — exact command line: `./matrix create <name> [--type=wp|laravel|symfony|drupal|joomla|grav] [--php-version=X.X] ...` + one paragraph on non-wp limits (nginx-only, wizard types, rollback).
- [ ] **Step 2: Run release bar** (Global Constraints list) — all green.
- [ ] **Step 3: Commit** `docs: multi-stack create in agent + readme`
- [ ] **Step 4: Report**: suites green count, any live-tier skips (live composer/network verification flagged for manual `create` of one laravel + one grav site).
