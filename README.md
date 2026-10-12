<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/WordPress-Dark-purple?style=for-the-badge&logo=wordpress&logoColor=white">
  <img src="https://img.shields.io/badge/WordPress-Light-blue?style=for-the-badge&logo=wordpress&logoColor=white" alt="WordPress Badge">
</picture>

<h1>WordPress Matrix</h1>

<p><strong>The one-command WordPress development environment for professionals.</strong></p>

<p>Multiple WordPress sites · Docker & Podman · Live TLS · Tunnel sharing · Offline test suite · PHP 7.4–8.3 · PHPStan Level 9</p>

<!-- ===== BADGE WALL ===== -->

```
[![GitHub stars](https://img.shields.io/github/stars/barunTayenjam/wordpress-matrix?style=flat-square&logo=github)](https://github.com/barunTayenjam/wordpress-matrix/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/barunTayenjam/wordpress-matrix?style=flat-square&logo=github)](https://github.com/barunTayenjam/wordpress-matrix/network/members)
[![GitHub license](https://img.shields.io/github/license/barunTayenjam/wordpress-matrix?style=flat-square)](https://github.com/barunTayenjam/wordpress-matrix/blob/main/LICENSE)
[![Build Status](https://img.shields.io/badge/Tests-189+37_passing-brightgreen?style=flat-square)](./tests/bash)
[![TDD-Ready](https://img.shields.io/badge/TDD-verified-blue?style=flat-square&logo=tdd)](./docs/TDD-IMPLEMENTATION.md)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat-square&logo=docker)](https://www.docker.com)
[![Podman](https://img.shields.io/badge/Podman-Ready-F17600?style=flat-square&logo=podman)](https://podman.io)
[![Node](https://img.shields.io/badge/Node-18+_blue?style=flat-square&logo=node.js)](https://nodejs.org)
```

</div>

---

## 🔥 What it is

One `./matrix` script replaces `docker compose up`, `wp cli`, `nginx` config, TLS certs, tunnels, and the whole dashboard. Spin up an entire WordPress network in seconds, edit any site's PHP version, pin WP core, share a tunnel with a client, and ship with confidence — all from a single entry point.

```bash
git clone https://github.com/barunTayenjam/wordpress-matrix.git
cd wordpress-matrix && chmod +x matrix
./matrix start          # db · redis · phpMyAdmin · frontend
./matrix create mysite  # your first site, ready in ~45s
open http://localhost:8500   # dashboard
```

---

## ⚡ Features at a glance

| Category | What you get |
|---|---|
| **Site lifecycle** | `create` · `start` · `stop` · `remove` · `clone` · `reset` · `edit` (memory/CPU limits) |
| **PHP freedom** | Per-site PHP 7.4 → 8.3, no single-version lock |
| **TLS first** | `matrix ssl` generates mkcert/openssl certs, HTTPS on `:port+1000`, pretty `<site>.test` domains |
| **Client-ready** | `matrix share` spins a cloudflared/ngrok/bore tunnel with one command |
| **Portability** | `matrix export/import` bundles site + DB + manifest for one-command portability |
| **WP version pinning** | `create --wp-version=6.4|6.5|6.6|latest`; verify with `matrix test` |
| **Multisite** | `create --multisite=subdirectory|subdomain` out of the box |
| **Presets** | `create --preset=woocommerce|bbpress|buddypress|elementor|multisite|blank` |
| **Code quality** | PHPStan Level 9 · WordPress CodeSniffer per-site, `matrix check` |
| **Health** | `matrix doctor` tells you exactly what's broken before you start |
| **Dashboard** | Real-time Node.js UI at `:8500` — status, flyouts, WP-CLI, terminal, activity log |
| **Docker OR Podman** | `$CONTAINER_RUNTIME` abstraction, no docker socket mounted |

---

## 🧪 Test status (verified)

Every phase ships red-then-green: failing test committed **before** the implementation.

```bash
# Offline stub suites — 189 assertions, no Docker daemon needed
tests/bash/site-state-test.sh  # 34/34
tests/bash/stubs-test.sh       # 4/4
tests/bash/ssl-test.sh         # 12/12
tests/bash/multisite-test.sh   # 16/16
tests/bash/presets-test.sh     # 14/14
tests/bash/doctor-test.sh      # 18/18
tests/bash/export-import-test.sh # 33/33
tests/bash/wp-version-test.sh  # 21/21
tests/bash/share-test.sh       # (share provider detection)
tests/bash/ops-test.sh         # 21/21

# Frontend
npm --prefix frontend test     # 37 tests

# Release bar (run before every commit)
bash -n matrix && bash -n scripts/*.sh
./matrix <cmd> --json | python3 -m json.tool
```

---

## 📦 Quick start

```bash
git clone https://github.com/barunTayenjam/wordpress-matrix.git wordpress-matrix
cd wordpress-matrix
chmod +x matrix

# Core services
./matrix start
./matrix status

# First site (PHP 8.3 default)
./matrix create mysite
open http://localhost:8201          # site
open http://localhost:8500          # dashboard
open http://localhost:8200          # phpMyAdmin

# Create with options
./matrix create legacy --php-version=7.4 --wp-version=6.5
./matrix create shop --preset=woocommerce
./matrix create team --multisite=subdomain

# Done with a site
./matrix remove mysite
./matrix clean
```

---

## 🔧 Complete command reference

### Environment

```bash
./matrix start              # db · redis · phpMyAdmin · frontend
./matrix stop               # stop everything + frontend
./matrix restart            # restart everything
./matrix status             # one-line overview
./matrix clean              # drop unused Docker/Podman resources
./matrix doctor             # bootstrap checks → exact fix commands
```

### Sites

```bash
./matrix list                                  # all sites
./matrix create <name> [--php-version=X.X]     # PHP 7.4–8.3
./matrix create <name> [--wp-version=6.4]      # pin WP core
./matrix create <name> [--multisite=subdir|subdomain]
./matrix create <name> [--preset=<preset>]     # woocommerce, bbpress, …
./matrix start/stop/remove <name>
./matrix clone <src> <dst>
./matrix reset <name>                            # fresh install
./matrix info <name> [--json]
./matrix url <name>
./matrix rest <name>                             # WP REST metadata
```

### TLS & domains

```bash
./matrix ssl <site> [--force] [--revoke] [--json]
./matrix domain <site> [--yes]                   # adds <site>.test to /etc/hosts
```

### Tunneling, export, presets

```bash
./matrix share <site> --yes                      # public tunnel (cloudflared/ngrok/bore)
./matrix export <site> --out bundle.tar.gz
./matrix import bundle.tar.gz newsite --yes
./matrix preset                                  # list presets
```

### WP core & quality

```bash
./matrix wp <site> <wp-cli args…>
./matrix check [<site> [<path>]]                 # phpcs + phpstan
./matrix test <site> --wp-versions=6.4,6.5       # compat matrix
```

### DB, logs, shells

```bash
./matrix shell wp/db/nginx <site>
./matrix logs [<site> | db | redis | phpmyadmin]
./matrix backup <site> --schedule=daily --retention=7
./matrix cron-install/cron-remove <site>
```

### Frontend

```bash
./matrix frontend start/stop/restart/status
```

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────┐
│  Host                                        │
│  ┌─────────────────┐  ┌──────────────────┐   │
│  │ Dashboard       │  │ matrix (CLI)     │   │
│  │ :8500 (Node)    │◄─┤ single entry pt  │   │
│  └─────────────────┘  └────────┬─────────┘   │
│                                │ shelling     │
└────────────────────────────────┼──────────────┘
                                 ▼
        ┌──────────────────────────────────────┐
        │ Docker/Podman                          │
        │  wp_<site> (php-fpm) ──┐               │
        │  nginx_<site> (443 on  │ port+1000)   │
        │  wp_db (MySQL)         │               │
        │  redis · phpmyadmin    │               │
        │  on-demand: wp-cli     │               │
        └──────────────────────────────────────┘
```

One entry point (`matrix`) → all mutation. Dashboard is read-only; it only invokes `matrix`. No Traefik router, no docker socket — pure host→container communication.

---

## 🛠 Setup & requirements

- **OS:** macOS or Linux (WSL2 supported)
- **Runtime:** Docker **or** Podman with `docker-compose`/`podman-compose`
- **Node.js 18+** (for the dashboard at `:8500`)
- Optional: `mkcert` (trusted certs), `cloudflared` (tunnels)

```bash
./matrix doctor     # tells you what's missing
```

Port map: sites start at **8201** (HTTP), **9201** (HTTPS) — phpMyAdmin **8200**, dashboard **8500**.

---

## 📝 Conventions you'll see in this repo

- **One script, one entry point.** Everything goes through `./matrix`; the dashboard never mutates state directly.
- **Generated files aren't source.** Per-site nginx configs, TLS certs, and `docker-compose.yml` service entries are generated by `matrix`; `./matrix repair` regenerates them.
- **JSON parity.** Every command supports `--json` and emits `{"success": …}` — the dashboard parses JSON, never text.
- **Runtime abstraction.** `$CONTAINER_RUNTIME` / `$DOCKER_COMPOSE` make Podman first-class.
- **Degrade, don't abort.** Missing `mkcert`, `cloudflared`, or `sudo` fall back gracefully — no unrelated command breaks.
- **Destructive ops confirm.** `/etc/hosts`, certs, and site removal take `--yes` and log to `logs/activity.log`.
- **Secrets stay off the CLI.** Env-var style only (the `MYSQL_PWD` pattern).

---

## 🧭 Roadmap

| Phase | Status |
|---|---|
| 0. Test infrastructure (offline stubs) | ✅ Done |
| 1. Auto-HTTPS + optional domains | ✅ Done |
| 2. Multisite at creation | ✅ Done |
| 3. Presets as files | ✅ Done |
| 4. `matrix share` tunneling | ✅ Done |
| 5. `matrix doctor` | ✅ Done |
| 6. Export / import bundles | ✅ Done |
| 7. WP version pinning + compat matrix | ✅ Done |
| 8. Scheduled backups + dashboard auth | ✅ Done |
| Upcoming | push/pull hosting, blueprint marketplace, mobile app |

Full methodology: [`docs/TDD-IMPLEMENTATION.md`](./docs/TDD-IMPLEMENTATION.md). Every phase is red → green with the failing test committed first.

---

## 🤝 Contributing

1. `[!INFO-0]` `git checkout -b feature/xxx`
2. Write the failing test first (`tests/bash/xxx-test.sh`).
3. Ship the implementation + `README.md` update in the same PR.
4. Keep the release bar green: `bash -n matrix && bash -n scripts/*.sh && ./matrix <cmd> --json | python3 -m json.tool`.

See [`AGENTS.md`](./AGENTS.md) for the full dev guide.

---

## 📜 License

MIT. Built for professional WordPress teams who want one command to rule them all.

<div align="center">

Made with 💙 by the WordPress Matrix team · Dashboard live at http://localhost:8500

[![GitHub](https://img.shields.io/badge/GitHub-black?style=for-the-badge&logo=github)](https://github.com/barunTayenjam/wordpress-matrix)
[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord)](https://discord.gg/placeholder)

</div>
