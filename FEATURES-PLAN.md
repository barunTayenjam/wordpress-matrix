# FEATURES-PLAN.md — Competitor Feature Incorporation

**Date:** 2026-10-12
**Status:** Approved for implementation
**Source:** `docs/competitor-analysis.html` (Local WP, Studio, DevKinsta, DDEV, wp-env, Lando, XAMPP)
**Scope:** `matrix`, `scripts/`, `frontend/`, `config/`, `tests/` only. No `wp_*` site content.

---

## 0. Standing constraints (non-negotiable)

These come from project history and bind every phase below:

1. **No router container.** Traefik was removed for Podman socket incompatibility; hostname routing was dropped for direct port access. All domain/TLS work is per-site nginx (or Apache) termination — no reintroduced proxy layer.
2. **One entry point.** Every feature lands as a `matrix` subcommand first; the dashboard shells out to it. No dashboard-only capability.
3. **JSON parity.** Every new command supports `--json` and emits `{"success":...}` via `output_json`/`error_json` with error codes; the frontend parses JSON, never text.
4. **Runtime abstraction.** All container calls go through `$CONTAINER_RUNTIME` / `$DOCKER_COMPOSE`; Podman is a first-class path.
5. **Generated files are not source.** New per-site nginx confs, certs, compose entries are generated; `./matrix repair` must be extended, not bypassed.
6. **Degrade, don't abort.** Missing optional tools (mkcert, cloudflared, sudo) produce a warning + fallback path, never a hard failure of unrelated commands.
7. **Destructive ops confirm.** Anything touching `/etc/hosts`, existing certs, or site state takes `--yes` (or prompts) and logs to `logs/activity.log`.
8. **Secrets off the command line.** Env-var passing only (`MYSQL_PWD` pattern); no passwords in argv or generated world-readable files.
9. **Tests ship with code.** `bash -n matrix && bash -n scripts/*.sh`; new helpers get stubbed offline tests under `tests/bash/` (site-state-test pattern); frontend additions get Jest cases. Release bar: `./matrix <cmd> --json | python3 -m json.tool`.
10. **Docs move with code.** Each phase updates `README.md` + `AGENTS.md` in the same change.

---

## Phase 1 — Auto-HTTPS + optional local domains (highest leverage)

**Goal:** Every site reachable over TLS on a predictable port; optional pretty hostname (`<site>.test`) via hosts file. Closes the biggest first-day gap vs Local/Studio/DevKinsta/DDEV.

**Design decisions:**

- **Port scheme:** HTTPS host port = site HTTP port + 1000 (8201→9201). Collision-checked with the existing allocation logic. Predictable, no router needed.
- **Cert source:** `mkcert` when installed (trusted CA); otherwise `openssl` self-signed with SAN `localhost,127.0.0.1,<LAN IP>,<site>.test`. Browser warning only in the fallback case; doc states it.
- **Cert storage:** `ssl-certs/<site>/` (already gitignored for key/crt/pem).
- **Domains:** `/etc/hosts` write is optional and sudo-gated. Without it, `https://localhost:9201` works. `matrix domain` never breaks if sudo is denied — prints the line to add manually.

### Tasks

| ID | Task | Files |
|----|------|-------|
| SSL-01 | `scripts/ssl-lib.sh`: `generate_site_cert <site>` (mkcert detect → openssl fallback, SAN builder, idempotent overwrite only with `--force`), `site_cert_fingerprint <site>` | new `scripts/ssl-lib.sh`, sourced from `matrix` |
| SSL-02 | nginx template: per-site conf gains `listen 443 ssl;` + cert paths; `compose-lib.sh` adds `- "9201:443"`-style mapping at create; `repair` regenerates both | `scripts/compose-lib.sh`, `matrix` (nginx template section) |
| SSL-03 | `matrix ssl <site> [--force] [--revoke]`: generate/remove cert + conf, restart that site's nginx, print URLs; `--json` emits `{site, https_url, cert_source, fingerprint}` | `matrix` |
| SSL-04 | Apache stack parity: 443 vhost in `config/docker/wp-apache` build context (follow-up; nginx first) | `config/docker/wp-apache/` |
| SSL-05 | `matrix domain <site> [hostname]`: default `<site>.test`; validates name via `config/validation.sh`; appends/removes `/etc/hosts` line (sudo, `--yes`); on sudo denial prints manual instruction and exits 0 | `matrix`, `scripts/ssl-lib.sh` |
| SSL-06 | Frontend: site flyout shows HTTPS URL + copy button; "Enable SSL" action calls `/api/sites/ssl` → `matrix ssl <site> --json` | `frontend/app.js`, `frontend/views/`, `frontend/public/` |
| SSL-07 | Tests: offline stub for cert-name resolution + port math; Jest for the new endpoint + copy handler | `tests/bash/ssl-test.sh`, `frontend/__tests__/` |

**Acceptance:** `./matrix ssl alpha` → `https://localhost:9201` serves the site (curl `-k` 200); `./matrix info alpha --json` includes `https_port`; `repair` restores conf+cert; Podman path verified.
**Effort:** ~2 days. **Risk:** low — additive ports; `--revoke` restores prior state.

---

## Phase 2 — Multisite at creation

**Goal:** `./matrix create <name> --multisite=subdirectory|subdomain` produces a working network like Local does.

**Design decisions:**

- Runs `wp core multisite-install` + `multisite-convert` through the existing on-demand `run_wp_cli` path — no new container.
- `subdomain` mode: documents wildcard limitation; matrix prints the hosts lines for the main + first subsite (no DNS magic; consistent with no-router decision).
- `.htaccess`/`nginx` map block generated into the site's conf at create (and by `repair`).

### Tasks

| ID | Task | Files |
|----|------|-------|
| MS-01 | Flag parsing + validation on `create` (`subdirectory` default, reject unknown values) | `matrix`, `config/validation.sh` |
| MS-02 | Post-install conversion via `run_wp_cli` (multisite-install, rewrite rules, wp-config `MULTISITE` constants) | `matrix` (create flow) |
| MS-03 | Per-stack rewrite generation: nginx location block / Apache `.htaccess` | `scripts/compose-lib.sh`, `matrix` |
| MS-04 | `matrix info --json` gains `multisite: bool` + `network_mode` | `matrix` |
| MS-05 | Tests: stubbed wp-cli assertion that conversion invoked with right args; validation tests | `tests/bash/` |

**Acceptance:** created multisite site loads `/wp-admin` network admin; second site created via UI works in subdir mode; `repair` preserves it.
**Effort:** ~1.5 days. **Risk:** medium — wp-config edits must preserve existing constants (precedent: `WORDPRESS_TABLE_PREFIX` rename fix).

---

## Phase 3 — Presets as shareable config files

**Goal:** Move the hardcoded `apply_preset` `case` into `config/presets/<name>.sh`; presets become files users can add/share.

### Tasks

| ID | Task | Files |
|----|------|-------|
| PS-01 | Preset file contract: each file defines `preset_plugins()`, `preset_theme()`, `preset_wp_config()`, `preset_post_install()`; sourced after name validation | new `config/presets/woocommerce.sh`, `bbpress.sh`, `blank.sh` (behavior-parity ports) |
| PS-02 | `apply_preset` → loader: validate preset name (reuse site-name charset rules), source file, run hooks; unknown preset = `error_json` listing available | `matrix` |
| PS-03 | `matrix preset` lists `config/presets/*.sh` with descriptions from a `preset_description()` | `matrix` |
| PS-04 | Tests: parity test that woocommerce/bbpress hooks produce identical WP-CLI call sequences pre/post refactor (golden list) | `tests/bash/presets-test.sh` |

**Acceptance:** `./matrix create shop --preset=woocommerce` behaves identically to today; dropping `config/presets/learn-dash.sh` in the dir makes it discoverable via `./matrix preset`.
**Effort:** ~1 day. **Risk:** low — pure refactor with golden-output test.

---

## Phase 4 — `matrix share` (tunnel helper)

**Goal:** One command exposes a running site for client review, Local-"Live Links" style, without a daemon of our own.

**Design decisions:**

- Wraps an existing provider binary; none installed → clear `error_json SHARE_NO_PROVIDER` with install hints (cloudflared preferred: no account for quick tunnels).
- Command runs in foreground (Ctrl-C tears down). `--json` prints the URL line as soon as the provider emits it, then keeps streaming nothing (documented).

### Tasks

| ID | Task | Files |
|----|------|-------|
| SH-01 | `scripts/share-lib.sh`: provider detect order `cloudflared → ngrok → bore`; arg builders per provider targeting the site's http port | new file |
| SH-02 | `matrix share <site> [--provider=...]`: verifies site running (`site_state`), starts tunnel, prints public URL + activity-log entry; requires `--yes` for non-localhost exposure warning | `matrix` |
| SH-03 | Frontend: "Share" action in flyout → streams URL into a modal | `frontend/` |
| SH-04 | Tests: provider detection table-driven offline test | `tests/bash/share-test.sh` |

**Acceptance:** with cloudflared present, `./matrix share alpha` prints a usable trycloudflare.com URL and site loads through it; without any provider, JSON error + hints.
**Effort:** ~1 day. **Risk:** low — read-only wrt site state.

---

## Phase 5 — `matrix doctor` + bootstrap polish

**Goal:** One command that answers "will this environment work?" — the onboarding story competitors win on.

### Tasks

| ID | Task | Files |
|----|------|-------|
| DR-01 | `matrix doctor`: container runtime + compose presence/version, Node/npm for frontend, port conflicts (8200/8500/1025/8025 and any allocated site ports), `.env` existence + `600` perms, disk headroom, DNS/hosts reachability check | `matrix` (new `cmd_doctor`), reuses `scripts/health-check.sh` runtime section |
| DR-02 | Output: human table + `--json` array of `{check, status: ok|warn|fail, detail}`; exit non-zero only on `fail` | `matrix` |
| DR-03 | `install` flow gains a `doctor` preflight and points at concrete fix commands per failure | `matrix` |
| DR-04 | Frontend: Health tab surfaces `doctor --json` | `frontend/` |
| DR-05 | Tests: table-driven checks with injected fake runtime/ports | `tests/bash/doctor-test.sh` |

**Acceptance:** on a clean machine, `doctor` exits non-zero naming each missing piece + the exact command to fix; on a working machine all-ok in <5s.
**Effort:** ~1 day. **Risk:** low.

---

## Sequencing & dependencies

```
Phase 3 (presets) ── independent, do first (cheap refactor, de-risks create)
Phase 1 (ssl)     ── independent
Phase 5 (doctor)  ── independent, ships value fastest for onboarding
Phase 2 (multisite) ── after Phase 1 (multisite conf must include ssl block when present)
Phase 4 (share)   ── after Phase 1 (share URL should prefer https when enabled)
```

Recommended order: **3 → 1 → 5 → 2 → 4**. Each phase is one merge-able unit with its own tests + docs; no phase blocks another.

## Out of scope (recorded, not planned)

- Push/pull hosting sync (WP Engine/Kinsta-style) — needs a remote-abstraction ADR first; revisit after Phase 1–5.
- Image optimizer add-ons, blueprint marketplace — GUI-first territory; we compete on CLI.
- Windows native support — WSL2 guidance in README is the current bar.

## Verification checklist (per phase merge)

- [ ] `bash -n matrix && bash -n scripts/*.sh`
- [ ] `bash tests/bash/site-state-test.sh` still 34/34 (+ new suite green)
- [ ] `npm --prefix frontend test` green
- [ ] New `--json` paths parse: `| python3 -m json.tool`
- [ ] Podman path exercised (`podman-compose` detection untouched)
- [ ] `README.md` + `AGENTS.md` updated in the same commit
- [ ] No `wp_*` paths touched
