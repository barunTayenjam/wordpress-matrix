# TDD-IMPLEMENTATION.md — Dev-Choice Roadmap, Test-Driven

**Date:** 2026-10-12
**Branch:** `feature/dev-choice-roadmap`
**Source:** `FEATURES-PLAN.md` (Phases 1–8), `docs/competitor-analysis.html`
**Method:** Strict red-green-refactor per phase. Every phase starts with failing tests committed before implementation. No `wp_*` paths.

---

## 0. Global test conventions (all phases)

**Offline stub harness** (from `tests/bash/site-state-test.sh`):
- `mktemp -d` sandbox; `PATH="$SANDBOX/bin:$PATH"`; stub `docker`/`matrix-compose-stub` driven by state files in `$STUB_DIR`
- Helpers loaded with `PROJECT_ROOT`, `COMPOSE_FILE`, `CONTAINER_RUNTIME`, `DOCKER_COMPOSE` exported
- Fail loudly: `set -uo pipefail`; `assert_eq` counters; exit non-zero on any FAIL

**Per-phase merge gate** (must pass before commit):
```bash
bash -n matrix && bash -n scripts/*.sh
bash tests/bash/site-state-test.sh        # 34/34 stays green
bash tests/bash/<new-suite>.sh            # new suite green
npm --prefix frontend test                # when frontend touched
./matrix <new-cmd> --json | python3 -m json.tool
```

**Naming:** `cmd_<verb>` CLI dispatch, `scripts/<domain>-lib.sh` for new helper modules, `*_json` emitters, `error_json CODE "msg"`, SCREAMING_SNAKE constants, `--yes` on every destructive op, `log_activity` on every mutation.

**Stub additions** (Phase 0 task below): extend `tests/bash/bin/docker` stub with `port`, `cp` subcommands writing to `$STUB_DIR` — same pattern as existing `ps`/`inspect` handling.

---

## Phase 0 — Test infrastructure (prereq for everything)

### RED
Create `tests/bash/stubs-test.sh`:
```bash
# T0.1: docker stub 'port' subcommand: 'docker port nginx_alpha 80/tcp' → reads $STUB_DIR/portmap.txt
assert_eq "port maps wp" "8201" "$(docker port nginx_alpha 80/tcp | sed 's/.*://')"
# T0.2: docker stub 'cp' record: writes '<dest>' to $STUB_DIR/copied.txt
docker cp /tmp/x container:/y && grep -q 'container:/y' "$STUB_DIR/copied.txt"
# T0.3: compose stub 'restart <svc>' appends to $STUB_DIR/restarted.txt
matrix-compose-stub restart nginx_alpha && grep -q nginx_alpha "$STUB_DIR/restarted.txt"
```
Run → all three FAIL (subcommands missing).

### GREEN
- `tests/bash/bin/docker`: add `port` case (read `$STUB_DIR/portmap.txt` lines `<name> <hostport>`; emit `80/tcp -> 0.0.0.0:<host>port`) and `cp` case (append args to `$STUB_DIR/copied.txt`).
- `tests/bash/bin/matrix-compose-stub`: add `restart` case appending service names.

### REFACTOR
Extract shared `stub_record "$file" "$line"` helper inside the stub scripts (they're plain bash; a tiny function each, no cross-file sourcing).

**Verify:** suite green, site-state suite untouched.

---

## Phase 1 — Auto-HTTPS + optional domains

### Contract
```
scripts/ssl-lib.sh
  generate_site_cert <site> [--force]     # → echoes cert dir; rc!=0 on failure
  cert_exists <site>                      # 0/1
  site_cert_fingerprint <site>            # sha256 fingerprint or ""
  build_cert_san <site>                   # stdout: SAN arg string
matrix
  ssl <site> [--force] [--revoke] [--json]
  domain <site> [hostname] [--json]       # /etc/hosts, sudo-gated
Port rule: https_port = site_port + 1000
Cert dir: $PROJECT_ROOT/ssl-certs/<site>/  (server.crt, server.key)
```
JSON shapes:
```json
{"success":true,"site":"alpha","https_port":9201,"url":"https://localhost:9201","cert_source":"mkcert|openssl","fingerprint":"..."}
{"success":false,"error":{"code":"SSL_SITE_NOT_FOUND|SSL_CERT_EXISTS|DOMAIN_SUDO_DENIED|...","message":"..."}}
```

### RED
Create `tests/bash/ssl-test.sh`:
```bash
# T1.1 cert naming/dirs
SSL_CERT_DIR="$SANDBOX/ssl-certs" generate_site_cert alpha
#   asserts: ssl-certs/alpha/server.crt+key exist; cert SAN contains 'localhost'
# T1.2 openssl fallback path (stub 'mktemp-free' env: PATH without mkcert)
#   asserts cert_source resolves openssl; fingerprint non-empty
# T1.3 idempotence: second generate without --force → rc!=0, mtime unchanged
# T1.4 port math: https_port_for alpha == $(get_site_port alpha) + 1000
# T1.5 conf generation: after ssl_enable alpha, sandbox nginx conf
#      contains 'listen 443 ssl' + 'ssl_certificate .*ssl-certs/alpha/server.crt'
# T1.6 revoke: removes conf ssl block + dir; site still serves http (stub compose restart recorded)
# T1.7 --json: valid JSON, success:true path; error path emits error_json SSL_SITE_NOT_FOUND for ghost
# T1.8 domain: with stubbed sudo (SANDBOX/bin/sudo recording argv) writes '<ip> alpha.test' line;
#      without --yes and non-tty → error_json
# T1.9 sudo denial: stub sudo exit 1 → DOMAIN_SUDO_DENIED + manual line printed, rc!=0
# T1.10 validation: matrix domain 'al pha' → rejected via validate_site_name
```
Run → all FAIL (no ssl-lib.sh).

### GREEN (minimal)
1. `scripts/ssl-lib.sh`: prefer `command -v mkcert`; else `openssl req -x509 -newkey rsa:2048 -nodes` with `-addext "subjectAltName=..."` (build SAN: `DNS:localhost,IP:127.0.0.1,IP:<LAN IP>,DNS:<site>.test` via `get_lan_ip` from helpers.sh). `chmod 600` key (convention T-05-02).
2. `matrix`: `cmd_ssl`, `cmd_domain`, `ssl_json` emitter; port math helper `https_port_for()` in helpers.sh; nginx conf template gains `%%HTTPS_BLOCK%%` marker replaced when cert exists (compose-lib template function).
3. Compose mapping: `compose_add_site` writes extra `"<https_port>:443"` when `--ssl` passed at create; `matrix ssl` for existing sites edits compose via existing `compose-lib` port-insert + `$DOCKER_COMPOSE restart nginx_<site>` (stubbed in tests).
4. `domain`: validates name, resolves host IP, appends `"$ip $host"` to `/etc/hosts` via `sudo tee -a` (never shell-interpolated), removal via `sudo sed -i` with anchored regex `^ *[0-9.]+ +<host>$`. Refusal path prints the exact line to add manually.

### REFACTOR
- Pull host-line manipulation into `hosts_line_add/remove` (pure-ish, testable with a temp hosts file env override `MATRIX_HOSTS_FILE` — tests use it; production default `/etc/hosts`).
- One `render_https_block <site> <port>` used by both create and `ssl` paths.

### Verify
```bash
bash tests/bash/ssl-test.sh && bash tests/bash/site-state-test.sh
./matrix ssl <real-site> ; curl -sk https://localhost:<p+1000> -o /dev/null -w '%{http_code}'
```

---

## Phase 2 — Multisite at creation

### Contract
```
matrix create <name> [--multisite=subdirectory|subdomain]
helpers.sh: site_is_multisite <site>            # reads wp-config marker
matrix: info --json gains {"multisite":bool,"multisite_mode":"subdirectory|subdomain|null"}
```

### RED
`tests/bash/multisite-test.sh`:
```bash
# T2.1 flag parse: --multisite=subdirectory accepted; --multisite=bogus → create aborts with validation error (stub run_wp_cli records calls; no container exec attempted)
# T2.2 wp-config markers: after create-with-multisite, sandbox wp-config.php contains
#      define('MULTISITE', true) + MULTISITE_SUBDOMAIN_INSTALL matching mode
# T2.3 rewrite generation: nginx conf contains /wp-admin network location block (subdirectory map)
# T2.4 apache: .htaccess multisite rules block present when stack=apache
# T2.5 info --json multisite fields true/false
# T2.6 repair preserves: run repair; markers still present (repair does not strip wp-config)
# T2.7 subdomain mode prints hosts lines for main site + first subsite (captured stdout)
# T2.8 wp-cli invocation list: run_wp_cli called with 'core multisite-install' exactly once,
#      after core install (ordering assert on recorded calls)
```

### GREEN
1. Parse `--multisite` in `cmd_create` arg loop (pattern of `--php-version`).
2. Post-install hook in create flow: if flag → `run_wp_cli <site> core multisite-install --subdomains=<0|1> ...` then write markers via existing wp-config edit helper (reuse the rename-safe table-prefix editor pattern from commit 1c1290c/0d40e92 lineage).
3. Template blocks per stack; guard so non-multisite sites emit none (regression: diff conf of plain create unchanged).
4. `show_info_json` reads markers.

### REFACTOR
`write_wp_config_constants <site> --mode=insert-if-absent` shared helper (multisite + future flags).

---

## Phase 3 — Presets as files

### Contract
```
config/presets/<name>.sh  # each defines:
  preset_description()        # one line
  preset_plugins()            # space-separated slugs, may be empty
  preset_theme()              # slug or ""
  preset_wp_config()          # KEY=VAL lines or ""
  preset_post_install()       # shell using run_wp_cli; optional
matrix preset            # lists dir + descriptions
apply_preset <site> <p>  # validates name (reuse site-name charset), sources file, runs hooks
error codes: PRESET_UNKNOWN, PRESET_INVALID_NAME
```

### RED
`tests/bash/presets-test.sh`:
```bash
# T3.1 golden parity: recorded WP-CLI sequence for woocommerce (fixture: expected lines file)
#      loader output == fixture (this is the migration safety net — capture fixture from CURRENT
#      hardcoded case BEFORE any change, commit fixture in same commit as loader)
# T3.2 unknown preset → error_json PRESET_UNKNOWN listing available
# T3.3 name validation: '../evil' → PRESET_INVALID_NAME, no file sourced (assert no side-effect file)
# T3.4 blank preset: no hooks called
# T3.5 matrix preset lists woocommerce, bbpress, blank with descriptions
# T3.6 dropped-in file: fixture 'demo.sh' in sandbox presets dir (env override MATRIX_PRESETS_DIR)
#      appears in list and applies
```

### GREEN
1. Capture golden fixtures FIRST from existing `apply_preset` case (temp script calls function with stubbed `run_wp_cli` recording). Commit fixtures.
2. Write three preset files porting the case branches verbatim.
3. Loader: `MATRIX_PRESETS_DIR` (default `$PROJECT_ROOT/config/presets`), validate, `source --` the file, run hooks with recorded stub.
4. `matrix preset` iterates dir.

### REFACTOR
Deduplicate repeated `wp plugin install ... --activate` sequences into loader-provided `preset_install_plugins()` helper presets may call.

---

## Phase 4 — `matrix share`

### Contract
```
scripts/share-lib.sh
  detect_share_provider        # echoes cloudflared|ngrok|bore|"" (first on PATH)
  provider_url_from_log <provider> <logfile>   # extracts public URL
matrix share <site> [--provider=P] [--json]
  # verifies site running (site_state), spawns provider for site port,
  # blocks; prints URL when detected; Ctrl-C cleanup trap kills child
errors: SHARE_NO_PROVIDER, SHARE_SITE_NOT_RUNNING
```

### RED
`tests/bash/share-test.sh`:
```bash
# T4.1 detection table: PATH with fake cloudflared → cloudflared; only fake bore → bore; empty → ""
# T4.2 SHARE_SITE_NOT_RUNNING when site_state says running=0 (reuse site-state stub pattern)
# T4.3 --yes gate: exposure warning printed once, proceeds with --yes, prompts without (non-tty → error)
# T4.4 url extraction: fixture log line 'https://xxxx.trycloudflare.com' → extracted
# T4.5 cleanup: interrupt after 0.2s (timeout cmd) → child pid killed (stub provider writes pidfile; assert pidfile gone)
# T4.6 --json emits {"provider":..., "url":...} line then keeps process (documented)
```

### GREEN
Foreground `exec`-style: trap EXIT/INT kill child. URL regex per provider (`trycloudflare.com`, `ngrok.io|ngrok-free.app`, bore `:<port>` host line). Activity-log entry on start/stop.

### REFACTOR
Single `wait_for_url <logfile> <pattern> <timeout>` poll loop (grep, not sleep-heavy: `until grep -m1`).

---

## Phase 5 — `matrix doctor`

### Contract
```
cmd_doctor [--json]
check registry (ordered): container_runtime, compose_tool, node_npm,
  ports(8200,8500,1025,8025 + allocated site ports), env_file (+stat 600),
  disk_headroom(>2GiB), hosts_reachability(.test entry optional), hooks_path
each check fn: check_<name> → echoes status=ok|warn|fail detail="..."
exit: 0 unless any fail; 1 on fail
```

### RED
`tests/bash/doctor-test.sh`:
```bash
# T5.1 each check isolated via env overrides (MATRIX_CHECK_PORTS, MATRIX_ENV_FILE, MATRIX_DISK_CMD)
#      fake outputs → assert ok/warn/fail mapping
# T5.2 exit code: any fail → 1; warn-only → 0
# T5.3 --json array shape [{check,status,detail}] parseable
# T5.4 hooks check: core.hooksPath unset → warn (memory: known inactive-hook gap), .githooks exists → ok
# T5.5 port busy detection: stub 'ss' reporting listener on 8500 → fail w/ detail naming pid cmd
```

### GREEN
Registry array of check names → loop, collect, render table/JSON. Reuse `scripts/health-check.sh` runtime probes by sourcing where pure.

### REFACTOR
`doctor --fix` NOT built (scope discipline); each fail detail prints the exact command a human runs.

---

## Phase 6 — Site export / import bundle

### Contract
```
matrix export <site> [--out FILE]      # FILE default backups/<site>-<date>-bundle.tar.gz
  bundle: manifest.json {site, php_version, stack, ports, wp_version, db_dump_sha256,
          table_prefix, multisite, created_at, matrix_version}
          + files/wp_ (site dir, excludes logs) + db/site.sql.gz
matrix import <bundle.tar.gz> <new-site> [--yes]
  # validates manifest schema + sha, restores files→wp_<new>, creates db,
  # imports dump with table-prefix preservation (reuse rename-safe editor),
  # regenerates compose+nginx via existing create path, remaps URLs (search-replace dry-run print)
errors: EXPORT_SITE_MISSING, IMPORT_MANIFEST_INVALID, IMPORT_SHA_MISMATCH, IMPORT_NAME_TAKEN
```

### RED
`tests/bash/export-import-test.sh`:
```bash
# T6.1 export of stubbed site (fixture site dir + fake dump) → tar exists, manifest fields correct
# T6.2 manifest sha matches dump file (corrupt dump → IMPORT_SHA_MISMATCH on import)
# T6.3 import into fresh sandbox: files restored, db create called (stub mysql records SQL),
#      compose+nginx regenerated with NEW name, old name absent
# T6.4 import refuses existing site (IMPORT_NAME_TAKEN) without --yes force-rename path
# T6.5 table prefix preserved (fixture wp-config with custom prefix; assert prefix string round-trips)
# T6.6 excludes: logs/, .git inside site dir absent from tar
# T6.7 --json both commands
```

### GREEN
Tar pipeline reuses backup.sh compression idiom + `MYSQL_PWD` env convention (no `-p` secrets). Manifest written last into tar (deterministic member order). Import = restore + create-site skeleton minus WP download (files present → skip core download in create flow via `--skip-download` branch).

### REFACTOR
Extract `bundle_manifest_read/validate` so `restore` (existing) can later adopt manifests without behavior change.

---

## Phase 7 — WP version pinning + compat matrix

### Contract
```
matrix create <name> --wp-version=6.4|6.5|6.6|latest   # downloads that core into site dir
helpers.sh: site_wp_version <site>   # from manifest/wp-includes/version.php grep
matrix test <site> --wp-version=V [--iterations=N]  # ephemeral wp_<site>_wpV containers,
  # runs matrix check <site> + wp core verify-checksums + smoke (rest) per combo,
  # tears down, prints table/JSON rows {site,php,wp,result}
```

### RED
`tests/bash/wp-version-test.sh`:
```bash
# T7.1 flag validation: '6.4' ok; 'banana' rejected; 'latest' alias resolves
# T7.2 create pins: sandbox site dir contains downloaded stub core (stub 'curl' serving fixture zip? —
#      instead: extract MATRIX_WP_FETCH_CMD hook; stub records URL containing /wordpress-6.4/)
# T7.3 site_wp_version reads version.php fixture ('$wp_version = 6.4')
# T7.4 test matrix: 1 php × 2 wp → 2 rows, each row result ok|fail from stubbed checks
# T7.5 teardown: no leftover containers in stub 'ps' after test cmd
# T7.6 --json rows parseable; table mode renders aligned columns
```

### GREEN
`MATRIX_WP_FETCH_CMD` indirection (default curl) keeps tests offline. Ephemeral combo runs reuse existing per-site create/start/stop functions with suffixed names (`wp_<site>_t<php><wp>`), isolated temp dirs, always `--yes`-free (non-destructive), trap cleanup.

### REFACTOR
Row renderer shared with `check --json` output for consistency.

---

## Phase 8 — Ops hygiene: scheduled backups, dashboard auth, hook wiring

### Contract
```
matrix backup <site> --schedule=<interval> --retention=N
  # writes .cron/<site>.cron line; matrix cron-install|cron-remove manage crontab via
  # ${(crontab -l)} diff — non-destructive, idempotent
frontend/app.js: token auth — MATRIX_DASHBOARD_TOKEN env (frontend + CLI both read .env);
  missing token → bind 127.0.0.1 only + banner; token set → Authorization check middleware
  + frontend login view; JWT not used (scope)
doctor: hooks check promotes wiring fix command (git config core.hooksPath .githooks)
```

### RED
`tests/bash/ops-test.sh`:
```bash
# T8.1 schedule write: .cron file content contains retention + site + interval; idempotent (no dup lines)
# T8.2 cron-install: fake crontab (MATRIX_CRONTAB_FILE) gains line; remove drops only our line
# T8.3 retention prune: fixture backups dir with 9 files, retention 3 → 6 removed, oldest first, activity-logged
# T8.4 auth middleware: supertest — no token env → GET / 200 + banner header; token set → 401 without,
#      200 with; /health exempt; static exempt-or-not decided by ONE test pinning chosen policy
# T8.5 token never logged: assert token absent from frontend.log fixture write path (grep logger calls)
```

### GREEN
Cron via marker-commented block (`# BEGIN matrix <site>` / `# END`) for clean removal. Auth = tiny middleware before routes, token compare `crypto.timingSafeEqual`. Policy pinned by T8.4: health + static asset exempt; all `/api/*` guarded.

### REFACTOR
Auth into `frontend/middleware/auth.js` (first extracted module) + Jest unit for middleware alone.

---

## Sequencing (unchanged from plan, now with rationale)

```
0 stubs → 3 presets (golden-parity refactor warms up harness)
        → 1 ssl → 5 doctor (doctor gains ssl + hooks checks)
        → 2 multisite → 7 wp-version (both touch create; merge order matters)
        → 6 export/import → 4 share (share should prefer https URLs; export benefits from manifests)
        → 8 ops hygiene (auth last: least user-visible, largest blast radius)
```
One PR per phase. Each PR: failing tests first (shown in PR description as RED output), then GREEN, then docs (README+AGENTS.md) + changelog entry.

## TDD discipline rules

1. **Commit RED before GREEN** (two commits per task minimum) — the failing-test commit is the spec.
2. **Never stub the thing under test** — stubs sit at container/compose/sudo/curl boundaries only.
3. **Golden fixtures before refactors** (Phase 3 pattern) for any behavior-preserving change.
4. **Every JSON contract change updates a Jest snapshot or bash assert in the same commit.**
5. **Regression = new test first**, then fix, referencing the task ID in the test name.
6. Suite runtime budget: each new bash suite <10s offline; if a test needs Docker, it belongs in a separate `tests/integration/` marked skip-by-default.

## Risk register (implementation-specific)

| Risk | Mitigation |
|---|---|
| wp-config editor corrupts user edits (Ph 2/6) | Reuse battle-tested rename path; round-trip fixture tests T2.6/T6.5 |
| SSL conf divergence nginx vs apache (Ph 1) | Apache behind SSL-04 flag; nginx first; shared render fn |
| Cron edits damage user crontab (Ph 8) | Marker-block diff only; dry-run print with `--print` flag |
| Ephemeral matrix containers leak (Ph 7) | trap-based teardown + T7.5 assertion |
| Auth breaks dashboard tests (Ph 8) | Policy pinned by test; token absent = old behavior exactly |
