<div align="center">

  <!-- Header & Capsule -->
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:21759B,50:1E4E79,100:0F2B3D&height=180&section=header&text=SiteMatrix&fontSize=48&fontAlignY=32&desc=One%20command.%20Every%20site.%20WordPress%2C%20Laravel%2C%20Drupal%20%26%20more.&descAlignY=55&descSize=18&animation=fadeIn&fontColor=ffffff" width="100%" alt="SiteMatrix banner" />

  <!-- SiteMatrix logo (brand) -->
  <p align="center">
    <img src="docs/logo.svg" alt="SiteMatrix logo" width="220" />
  </p>

  <!-- Badge Wall — live repo metrics + project health -->
  <!-- Stars, Forks, Last Commit -->
  [![Stars](https://img.shields.io/github/stars/barunTayenjam/sitematrix?style=for-the-badge&logo=github&label=Stars)](https://github.com/barunTayenjam/sitematrix/stargazers)
  [![Forks](https://img.shields.io/github/forks/barunTayenjam/sitematrix?style=for-the-badge&logo=github&label=Forks)](https://github.com/barunTayenjam/sitematrix/network/members)
  [![Last Commit](https://img.shields.io/github/last-commit/barunTayenjam/sitematrix/main?style=for-the-badge&logo=git&label=Last%20Commit)](https://github.com/barunTayenjam/sitematrix/commits/main)

  <!-- Project Health & Quality Badges -->
  [![Tests](https://img.shields.io/badge/tests-189%20bash%20%2B%2037%20jest-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](tests/bash)
  [![TDD](https://img.shields.io/badge/method-red%20→%20green%20→%20refactor-orange?style=for-the-badge)](docs/TDD-IMPLEMENTATION.md)
  [![PHPStan Level 9](https://img.shields.io/badge/PHPStan-Level%209-84CC16?style=for-the-badge&logo=php&logoColor=white)](https://phpstan.org)
  [![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
  [![Podman](https://img.shields.io/badge/Podman-892CA0?style=for-the-badge&logo=podman&logoColor=white)](https://podman.io)
  [![WordPress](https://img.shields.io/badge/WordPress%207.4–8.3-21759B?style=for-the-badge&logo=wordpress&logoColor=white)](https://wordpress.org)
  [![Node](https://img.shields.io/badge/Dashboard-Node%2018+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
  [![License](https://img.shields.io/badge/license-MIT- blue?style=for-the-badge)](LICENSE)

</div>

---

## 🚀 Getting Started

```bash
git clone https://github.com/barunTayenjam/sitematrix.git
cd sitematrix
chmod +x matrix

# Check your machine is ready — names every missing piece + the exact fix
./matrix doctor

# Start core services: MySQL, Redis, phpMyAdmin, dashboard
./matrix start

# Create your first site (PHP 8.3, port assigned automatically)
./matrix create mysite
```

> [!TIP]
> Not sure where to start? `./matrix doctor` checks the container runtime, compose tool,
> ports, `.env` perms, disk headroom, and DNS — then prints the exact command to fix each failure.

Real session — what a site creation looks like:

```console
$ ./matrix create mysite
✅ Created .env file with generated credentials
✅ Created docker-compose.yml
✅ Created default nginx configuration
✅ Site 'mysite' created successfully with PHP 8.3 (nginx)
✅ Site 'mysite' started and ready!

$ ./matrix ssl mysite --json
{"success":true,"site":"mysite","https_port":9201,"url":"https://localhost:9201",
 "cert_source":"mkcert","fingerprint":"SHA256:9f3c…"}
```

---

## ✨ Features

- [x] **One entry point** — every operation is a `./matrix` subcommand; the dashboard only invokes it
- [x] **Per-site PHP 7.4 → 8.3** — run legacy and modern sites side by side (`--php-version=7.4`)
- [x] **Stack-specific provisioning & pinning** — `--wp-version=6.4|6.5|6.6|latest`, then `matrix test` sweeps them
- [x] **Auto-HTTPS** — mkcert (trusted CA) with openssl fallback; TLS on `port+1000`, `<site>.test` domains optional
- [x] **Multisite at creation** — `--multisite=subdirectory|subdomain`, nginx/Apache rewrites generated
- [x] **Shareable presets** — drop a `.sh` into `config/presets/`; `--preset=woocommerce` just works
- [x] **Client-ready tunnels** — `matrix share` wraps cloudflared/ngrok/bore, one command, Ctrl-C to tear down
- [x] **Portable bundles** — `export`/`import` a site as tar.gz: manifest + files + sha-verified DB dump
- [x] **Scheduled backups** — `--schedule=daily --retention=7`, marker-block crontab sync
- [x] **Docker *and* Podman** — runtime abstraction everywhere; no docker socket mounted
- [x] **Code quality built in** — PHPStan Level 9 + stack-specific standards per site
- [x] **JSON everywhere** — every command emits parseable `{"success":…}`; the dashboard never scrapes text
- [x] **Live dashboard** — real-time status, site flyouts, activity log, keyboard shortcuts at `:8500`
- [x] **Doctor** — bootstrap checks that degrade with a fix-command, never a dead end

<details>
<summary><b>Why matrix? (vs Local WP, DDEV, Lando, wp-env, XAMPP)</b></summary>

Built after auditing 7 competitor tools. The gaps matrix closes on day one:

| Need | matrix | Local/Studio | DDEV/Lando | wp-env |
|---|---|---|---|---|
| Multi-site in seconds | ✅ one command | ✅ GUI | ✅ | ⚠️ single-site |
| Works on Podman | ✅ first-class | ❌ | ⚠️ | ❌ |
| Zero-daemon offline tests | ✅ 189 stub asserts | ❌ | ❌ | ❌ |
| Per-site WP core version pinning | ✅ | ⚠️ | ⚠️ | ⚠️ |
| One-command public tunnel | ✅ | ✅ paid | ⚠️ | ❌ |
| Portable tar.gz bundle w/ manifest | ✅ | ⚠️ | ❌ | ❌ |
| No router container, no root daemon | ✅ | ❌ | ❌ | ❌ |
| JSON CLI for automation | ✅ every cmd | ❌ | ⚠️ | ⚠️ |

Full analysis: [`docs/competitor-analysis.html`](docs/competitor-analysis.html)
</details>

---

## 📖 Command Reference

<details open>
<summary><b>Lifecycle</b></summary>

```bash
./matrix start [site]      # no arg: core services · with arg: that site
./matrix stop  [site]      # no arg: everything · with arg: that site
./matrix restart [site]
./matrix status            # overview table
./matrix list              # all sites; --json for machine-readable
./matrix clean             # prune unused containers/images/volumes
```
</details>

<details>
<summary><b>Create & configure</b></summary>

```bash
./matrix create shop                                # WordPress, PHP 8.3 default
./matrix create legacy --php-version=7.4            # side-by-side PHP
./matrix create lab    --wp-version=6.4             # pin WP core (6.4|6.5|6.6|latest)
./matrix create team   --multisite=subdomain        # network at creation
./matrix create shop   --preset=woocommerce         # presets from config/presets/
./matrix preset                                     # list available presets
./matrix edit site --memory=512M --cpu=1            # per-site resource limits
./matrix clone src dst · ./matrix reset name · ./matrix remove name
```

**Other stacks** — `--type=` picks the runtime, webroot and provisioning. PHP floors are enforced at create.

```bash
./matrix create shop     --type=laravel            # PHP ≥ 8.2 · public/ · composer create-project
./matrix create api      --type=symfony            # PHP ≥ 8.2 · public/
./matrix create cms      --type=drupal             # PHP ≥ 8.3 · web/ · settings.php pre-seeded
./matrix create intranet --type=joomla             # PHP ≥ 8.1 · Joomla 5 · wizard creds printed at create
./matrix create docs     --type=grav               # PHP ≥ 8.1 · no database at all
```

`--wp-version`, `--multisite`, `--preset` and `stack=apache` are WordPress-only. `wp-cli`, `check`
and `optimize` refuse non-wp sites; clone/reset/export/import adapt per type.
</details>

<details>
<summary><b>TLS, domains, tunnels</b></summary>

```bash
./matrix ssl mysite [--force] [--revoke] [--json]   # HTTPS on :9201 (port+1000)
./matrix domain mysite mysite.test [--yes]          # /etc/hosts entry, sudo-gated
./matrix share mysite --yes                         # cloudflared → ngrok → bore
```
</details>

<details>
<summary><b>Portability & ops</b></summary>

```bash
./matrix export mysite --out bundle.tar.gz          # manifest + files + sha'd dump
./matrix import bundle.tar.gz newsite [--yes]
./matrix backup mysite --schedule=daily --retention=7
./matrix cron-install mysite · ./matrix cron-remove mysite
```
</details>

<details>
<summary><b>WP core & quality</b></summary>

```bash
./matrix wp mysite plugin install query-monitor --activate
./matrix check [site] [path]                        # phpcs + phpstan level 9
./matrix test lab --wp-versions=6.4,6.5 [--json]    # compat matrix rows
./matrix rest mysite                                # REST API metadata
```
</details>

<details>
<summary><b>Introspection</b></summary>

```bash
./matrix doctor [--json]                            # bootstrap checks
./matrix info mysite [--json]
./matrix url mysite
./matrix logs [site|db|redis|phpmyadmin]
./matrix shell wp|db|nginx [site]
scripts/health-check.sh                             # runtime deep-check
```
</details>

---

## 🏗️ Architecture

```
┌────────────────────────────── host ──────────────────────────────┐
│                                                                  │
│   matrix (bash) ◄── one entry point; validates, mutates, logs    │
│      │                                                           │
│      ├── generated state: docker-compose.yml · config/nginx/*    │
│      ├── ssl-certs/<site>/ · .cron/<site>.cron · backups/        │
│      └── frontend (Node/Express :8500) ── shells out to matrix   │
│                                                                  │
└──────────────────────────────┬───────────────────────────────────┘
                               ▼  $CONTAINER_RUNTIME / $DOCKER_COMPOSE
┌────────────────────────── containers ────────────────────────────┐
│  wp_<site> (wordpress:phpX.X-fpm | matrix-php:X.X) ⇄ nginx_<site>  │
│                    webroot: / · public/ (laravel,symfony) · web/   │
│                            (drupal) — grav has no database         │
│  wp_db (MySQL :3306) · redis · phpmyadmin (:8200)                │
│  wp-cli → ephemeral wordpress:cli, joins the live db network     │
└──────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> Generated files are not source. `docker-compose.yml` entries, nginx confs, and certs
> are produced by `matrix` — `./matrix repair` regenerates them at any time.

---

## 🧪 Testing & TDD

Strict red → green → refactor per phase. **Failing tests are committed before the implementation.**

Methodology: [`docs/TDD-IMPLEMENTATION.md`](docs/TDD-IMPLEMENTATION.md)

| Suite | Asserts | What it pins |
|---|---|---|
| `site-types-test.sh` | 139 | 6-stack registry, provisioning, compose/nginx/repair type-awareness |
| `site-state-test.sh` | 34 | Compose + live-container state seam |
| `stubs-test.sh` | 4 | docker/compose stub infrastructure |
| `ssl-test.sh` | 12 | cert generation, port math, domains |
| `multisite-test.sh` | 20 | multisite-at-creation contract |
| `presets-test.sh` | 17 | golden-parity preset loader |
| `doctor-test.sh` | 18 | every check + exit codes |
| `export-import-test.sh` | 33 | bundle round-trip, sha, name rules |
| `wp-version-test.sh` | 21 | pinning + compat matrix |
| `share-test.sh` | 16 | provider detection, url extraction, cleanup |
| `ops-test.sh` | 21 | schedules, crontab blocks, auth middleware |

All stub suites run **offline** — no Docker daemon needed. Plus 62 Jest tests for the dashboard API.

```bash
# the release bar — run before every commit
bash -n matrix && bash -n scripts/*.sh
for t in tests/bash/*-test.sh; do bash "$t"; done
npm --prefix frontend test
./matrix info <site> --json | python3 -m json.tool
```

---

## 🗺️ Roadmap

- [x] Phase 0 — offline stub test infrastructure
- [x] Phase 1 — auto-HTTPS + optional domains
- [x] Phase 2 — multisite at creation
- [x] Phase 3 — presets as files
- [x] Phase 4 — `matrix share` tunnels
- [x] Phase 5 — `matrix doctor`
- [x] Phase 6 — export/import bundles
- [x] Phase 7 — WP version pinning + compat lab
- [x] Phase 8 — scheduled backups + dashboard token auth
- [x] Multi-stack — `--type=laravel|symfony|drupal|joomla|grav` alongside wp
- [ ] Push/pull hosting sync (WP Engine/Kinsta-style)
- [ ] Apache-stack TLS parity
- [ ] Blueprint marketplace

---

## 🤝 Contributing

```bash
git checkout -b feat/my-feature
# 1. failing test first  →  tests/bash/feat-test.sh
# 2. implementation      →  keep the release bar green
# 3. docs in same commit →  README.md + AGENTS.md
```

Dev guide: [`AGENTS.md`](AGENTS.md) · Architecture Q&A: [`DFD.md`](DFD.md) · Feature plan: [`FEATURES-PLAN.md`](FEATURES-PLAN.md)

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0F2B3D,50:1E4E79,100:21759B&height=120&section=footer" width="100%" alt="" />

</div>

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.