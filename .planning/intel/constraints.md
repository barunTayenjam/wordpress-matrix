# Synthesized Constraints

## From FLOW_REVIEW.md (SPEC, precedence 0)

### C-001: Password transmission protocol
- **Type**: protocol
- **Source**: FLOW_REVIEW.md (#10)
- **Content**: All database client invocations (mysql, mysqldump) MUST pass credentials via MYSQL_PWD environment variable or defaults-extra-file. Inline `-p"$PASSWORD"` CLI arguments are forbidden. Affects matrix, common.sh, backup.sh, reset.sh, clone.sh — 11 call sites.

### C-002: .env file security
- **Type**: nfr
- **Source**: FLOW_REVIEW.md (#11)
- **Content**: .env files MUST be created with `chmod 600` to prevent world-readable credentials. Applies to all .env write sites.

### C-003: Gitignore credential guard
- **Type**: nfr
- **Source**: FLOW_REVIEW.md (#14)
- **Content**: .gitignore MUST include .env patterns. Pre-commit hook or CI check MUST reject commits containing MYSQL_PASSWORD patterns.

### C-004: Random credential generation
- **Type**: nfr
- **Source**: FLOW_REVIEW.md (#4)
- **Content**: Default passwords MUST NOT be hardcoded. Use `openssl rand -base64 16` for password generation at .env creation time.

### C-005: Error protocol standard
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#6)
- **Content**: Adopt a consistent error protocol: `die()` function that prints message and exits 1 for hard failures; `return 1` reserved for validation where caller may retry. No bare `exit 1` without message.

### C-006: Dispatch architecture
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#12)
- **Content**: Replace flat `case` dispatch with associative array mapping command names to function references. Enable `--help` derivation and `matrix help <cmd>` from the dispatch table.

### C-007: Docker/Compose abstraction layer
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#11)
- **Content**: Always use Compose for up/down/restart; use `docker exec` for runtime operations. Remove raw `docker start/stop` fallback paths. Document the contract in a comment block.

### C-008: Bootstrap library extraction
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#8)
- **Content**: Extract the duplicated ~40-line bootstrap (DOCKER_COMPOSE detection, color/logger defs, .env loading) into a single `lib/bootstrap.sh`. Both `matrix` and `common.sh` MUST source it from the same location.

### C-009: Domain module boundaries
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#9)
- **Content**: Matrix functions MUST be split into domain modules: `lib/site.sh`, `lib/env.sh`, `lib/db.sh`, `lib/devtools.sh`. Each module owns its global state and exposes a clear function API. Modules sourced at matrix startup.

### C-010: Per-site credential isolation
- **Type**: schema
- **Source**: FLOW_REVIEW.md (#12)
- **Content**: Database credentials MUST be scoped per site in `wp_<site>/.env`. Global `.env` holds only infrastructure secrets (root DB password, Redis). All DB call sites MUST read site-local env.

### C-011: Shell test framework
- **Type**: nfr
- **Source**: FLOW_REVIEW.md (#14)
- **Content**: Shell scripts MUST have automated test coverage using bats or ShellSpec. Critical paths: site creation/removal, port allocation, validation functions, DB import/export.

### C-012: Health check JSON output
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#5)
- **Content**: `matrix health --json` MUST emit structured JSON matching the format of status/info JSON commands.

### C-013: Command alias discipline
- **Type**: api-contract
- **Source**: FLOW_REVIEW.md (#6)
- **Content**: `./matrix test` MUST NOT alias to `run_checks`. Either remove the test dispatch entry or route it to a real test runner (PHPUnit/Jest).

## From IMPROVEMENT_PLAN.md (SPEC, precedence 2)

### C-014: Resource limits via compose
- **Type**: schema
- **Source**: IMPROVEMENT_PLAN.md (1.3)
- **Content**: Container memory and CPU limits configured in docker-compose.yml per service using `deploy.resources.limits`.

### C-015: Backward compatibility constraint
- **Type**: nfr
- **Source**: IMPROVEMENT_PLAN.md (Implementation Notes)
- **Content**: All improvements must maintain backward compatibility. Use environment variables for new configurations. Graceful degradation when features are unavailable.
