---
status: fixed
trigger: "./matrix start su26 - site exists but has no exposed port"
created: 2026-05-08
updated: 2026-05-08
---

## Symptoms

- **Expected behavior**: The site should be accessible at a port like localhost:8100
- **Actual behavior**: The site says it started but has no exposed port
- **Error messages**: None (silent failure)
- **Timeline**: Only this site - other sites may work fine
- **Reproduction**: Triggered by running `./matrix start su26`

## Current Focus

hypothesis: "Site 'su26' was created outside the matrix workflow (manually copied or cloned), so docker-compose.yml lacks its service definitions. When `./matrix start su26` runs, it only does `docker start` (no port mapping added), and `show_urls` returns empty since there's no port in compose or running container."
next_action: "Verify if site was created via `./matrix create` or via scripts/clone.sh. Check compose file for similar orphaned sites. Propose fix: run site re-registration (add to compose with fresh port)."
reasoning_checkpoint: "docker-compose.yml has no `wp_su26` or `nginx_su26` entries — confirmed. The `get_container_port()` function relies on live container port bindings, which are absent. Fix requires adding the missing service definitions."

## Eliminated Hypotheses

- ~~Port conflict~~ — no other site uses su26; get_next_port() not called since site not in compose
- ~~Container crash~~ — no container definitions exist in compose to crash
- ~~Docker daemon not running~~ — db/redis services would also fail; this is isolated to su26

## Eliminated Hypotheses

## Notes

## Resolution

- **root_cause:** Site 'su26' existed as a directory but was missing from `docker-compose.yml` — no `wp_su26` / `nginx_su26` service definitions were ever added. The `./matrix start` command tried to `docker start` existing containers directly (bypassing port mapping), and `show_urls` / `get_container_port` found no port in compose or running containers.
- **fix:** Added `wp_su26` and `nginx_su26` service definitions to `docker-compose.yml` using PHP 8.3 image (matching the site's `wp-config-docker.php`) and port 8202. Nginx config already existed at `config/nginx/su26.conf`. Fixed in 1 cycle.
- **specialist_hint:** general
- **resolved_by:** session-manager
- **resolved_at:** 2026-05-08