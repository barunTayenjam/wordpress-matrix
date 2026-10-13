# Multi-PHP-stack site support (pre-sitematrix rename)

Date: 2026-10-13
Status: Draft

## Intent and why

`wordpress-matrix` manages WordPress sites only. Adding the most-used PHP
frameworks/CMSes — **Laravel, Symfony, Drupal 11, Joomla 5, Grav** — turns the
platform into a general PHP site manager and justifies the later rename to
`sitematrix`. **The rename itself is out of scope for this change**; support
lands first.

Popularity basis (SearXNG 2026 lookups, e.g. Zenrows/ServerAvatar): WordPress
dominant CMS (already supported), Joomla 2nd CMS, Drupal 3rd; Laravel top PHP
framework, Symfony 2nd; Grav most-used flat-file CMS.

## Goals

- `./matrix create <name> --type=<wp|laravel|symfony|drupal|joomla|grav>`
  provisions and auto-starts a working site of that type, same UX as WP today
  (port assignment, dashboard entry, logs, start/stop/remove, export/import).
- `wp` is the default type — every existing command behaves identically.
- One runtime image pattern for all non-WP types; no per-type Dockerfiles.
- Existing offline test suites keep passing; new suites cover type dispatch.

## Non-goals / anti-goals

- No repo/CLI rename (later request).
- No apache stack for new types (nginx only; apache remains WP-only).
- No Magento, TYPO3, Craft, Statamic, CodeIgniter.
- No WP-CLI equivalents wired for drush/artisan/symfony console into
  `matrix <cmd>` in this change — `matrix shell wp_<site>` covers it. (Follow-up
  can add `matrix console <site> ...`.)
- No preset files for new types (presets stay WP-only, guarded).
- No CI of any new kind.

## Constraints

- Bash CLI + generated docker-compose/nginx architecture stays as-is
  (Hindsight: single-entry `matrix` CLI owns all mutation).
- Sites keep `wp_<name>` directory/container naming until the rename.
- Offline-first tests: stub-based suites under `tests/bash/`, no daemon needed.

## Design

### Type selection and persistence

- `create_site` gains `--type=` (both `--type=x` and `--type x` forms, matching
  existing option parsing). Default `wp`.
- Validation: type ∈ {wp,laravel,symfony,drupal,joomla,grav}; unknown → error
  listing valid types.
- PHP version floors per type (validated at create, default bumps to the floor):
  - wp: 7.4+ (unchanged)
  - joomla, grav: 8.1+
  - laravel, symfony: 8.2+
  - drupal: 8.3+
- Persisted as `wp_<name>/.matrix-type` (mirrors existing `.matrix-stack`
  pattern). Missing file ⇒ `wp` (backward compat for existing sites).
- `--wp-version` and `--multisite` rejected for non-wp types.

### Composer runtime (builder-check decision #2)

- Composer is baked into `matrix-php` (added in the same Dockerfile). Composer
  create-project runs inside a one-shot `matrix-php:<ver>` container, **not**
  `composer:2` — symfony/drupal declare `ext-*` platform requirements
  (intl, zip, pdo_mysql) that a plain composer image fails, aborting
  create-project. One image still serves both runtime and provisioning.

### Per-type config seeding (builder-check decision #3)

- **laravel:** create-project generates its own `.env`; we **patch keys** in
  place (`DB_HOST=db`, `DB_DATABASE=<name>_db`, `DB_USERNAME`, `DB_PASSWORD`),
  never overwrite the generated file. APP_KEY generated as designed.
- **drupal:** the recommended-project installer reads no `.env` — seed
  `web/sites/default/settings.php` before first visit with DB creds + hash
  salt so the wizard needs no typing (parity with WP's pre-wired DB).
- **joomla:** wizard at first visit as designed (writes its own
  configuration.php); creds shown in create output for easy copy.
- **grav:** nothing to seed (no DB).

### Failure handling (builder-check decision #4)

- Non-wp provisioning failure ⇒ **rollback**: remove the site dir and compose
  entry, report the failed step. A half-composer download is a useless site
  state; differs from WP's best-effort because WP failures (pin, db-down)
  leave a fully valid site, composer failures don't.
- Acceptance per type: laravel/symfony/grav serve their welcome page;
  joomla/drupal show the install wizard with DB pre-wired (joomla creds
  printed).

### WP-shaped commands on non-wp types (builder-check decision #1)

- **Gate with the same "not supported for <type>" error:** `matrix wp`,
  presets, perf/optimize, `test` (compat lab), `update-core`,
  `search-replace`, `cache-clear`, `--wp-version`, `--multisite`.
- **Adapt:** `clone` respects type (copies `.matrix-type`, skips DB clone for
  grav, skips wp-config sed for non-wp); `check` errors for non-wp with a
  pointer to phpstan setup as follow-up.
- **Reset:** re-runs the create flow for the site's existing type (fresh
  install of that type, not always WP).

### Provisioning (3 mechanical patterns)

| type | pattern | webroot | DB |
|---|---|---|---|
| wp | existing flow (image copy + wp-cli.phar) | `/var/www/html` | yes |
| joomla | zip download + extract (Joomla 5 zip URL), wizard at first visit | `/var/www/html` | yes |
| laravel | `composer create-project laravel/laravel` | `/var/www/html/public` | yes |
| symfony | `composer create-project symfony/skeleton` + (optionally webapp) | `/var/www/html/public` | yes |
| drupal | `composer create-project drupal/recommended-project` | `/var/www/html/web` | yes |
| grav | `composer create-project getgrav/grav` | `/var/www/html` | none |

- Composer create-project runs in a one-shot `matrix-php:<ver>` container
  mounting the site dir (composer is baked into that image — see Composer
  runtime above).
- `.env` is written for laravel/symfony/drupal with DB creds (`DB_HOST=db`,
  `DB_DATABASE=<name>_db`, user/password from the platform `.env`), plus
  `APP_KEY` for laravel generated via a one-shot `php artisan key:generate`
  in the site container after first start.
- Grav skips DB creation (and skips the db dump on export).
- Files chowned www-data, same as WP flow.

### Runtime image

- New `config/docker/php-site/Dockerfile`: `ARG PHP_VERSION`; `FROM
  php:${PHP_VERSION}-fpm`; installs the common superset via
  `docker-php-ext-install`/`install-php-extensions`: `pdo_mysql`, `intl`,
  `zip`, `gd`, `bcmath` (laravel+drupal+joomla needs). Built on demand at
  create time as `matrix-php:<ver>` (mirrors existing `wp-matrix-apache:<ver>`
  build pattern).
- `compose_add_site` takes the type: wp keeps `wordpress:php<ver>-fpm`
  unchanged; other types get `matrix-php:<ver>` and no `WORDPRESS_DB_*` env
  (creds live in the app `.env` instead).
- `depends_on: db` kept for all types except grav (dropped for grav).

### Nginx

- Conf template gains per-type `root` (table above). Everything else (php-fpm
  pass, deny dotfiles, try_files) unchanged — already framework-agnostic.
- Grav additionally needs `client_max_body_size 25m;` for admin uploads
  (ponytail: fine to add for all types, harmless).

### WP-only surfaces, gated by type

- `matrix wp`, presets (`apply_preset`), perf mu-plugins/object-cache copy,
  `apply_performance_tweaks` wp-config block, `--wp-version`, `--multisite`,
  `matrix test` (compat lab): non-wp site ⇒ clear error naming the type.
- `optimize` (mu-plugin copy) — wp only; no-op with a notice otherwise.
- Drupal `trusted_host_patterns`/site uuid and Joomla/grav post-install stay
  manual (web wizard) in this change.

### Stack-agnostic paths (verified already fine)

- export/import: tar files + `mysqldump` — no wp-cli dependency; grav variant
  skips the db member.
- `site_state` (Compose-first, live-container fallback) — image string still
  contains the php version; gains a `type=` key from `.matrix-type`.
- status/list/info/logs/shell/start/stop/remove/backup/share/doctor: no change
  beyond displaying type.

### Frontend dashboard

- Create form gains a "Type" select (6 options, wp default); POST
  `/api/sites/create` passes `type` through. Express validation whitelist.
- Site cards + flyout show a type badge. No other UI work.

## Testing

- New `tests/bash/site-types-test.sh` (stub-based, same harness as
  `site-state-test.sh`): type validation, floor enforcement, `.matrix-type`
  write/read, compose_add_site image+env selection per type, nginx root per
  type, wp-only gating errors, grav no-db path.
- Existing 10 suites + frontend Jest must pass unchanged.

## Open items (builder's call unless flagged)

- Exact symfony flavor (`symfony/skeleton` vs `symfony/website-skeleton`
  successor `webapp`): recommend `symfony/skeleton` + note in output; upgrade
  path documented.
- Extension list trim/expand after first real `create` of each type.
- Joomla zip URL pinning strategy (fixed major, floating minor) — mirror the
  existing `resolve_wp_version` approach.
