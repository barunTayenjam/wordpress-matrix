#!/bin/bash
# Doctor library for wordpress-matrix.
# Environment/bootstrap checks on top of ./matrix health (FEATURES-PLAN.md Phase 5).
# Contract: each check_<name> echoes "status=ok|warn|fail" plus "detail=...".
# cmd_doctor [--json] runs the ordered registry, renders a table or a JSON
# array [{check,status,detail}], and exits 1 only when a check failed.
# Scope discipline: doctor --fix is NOT built — each fail prints the exact
# command a human runs.

set -uo pipefail

# Isolation overrides (tests); defaults suit normal use.
MATRIX_CHECK_PORTS="${MATRIX_CHECK_PORTS:-8200 8500 1025 8025}"
MATRIX_ENV_FILE="${MATRIX_ENV_FILE:-$PROJECT_ROOT/.env}"
MATRIX_HOSTS_FILE="${MATRIX_HOSTS_FILE:-/etc/hosts}"
MATRIX_DISK_CMD="${MATRIX_DISK_CMD:-df -Pk "$PROJECT_ROOT"}"

_check_emit() { echo "status=$1 detail=$2"; }

check_container_runtime() {
    if $CONTAINER_RUNTIME info >/dev/null 2>&1; then
        _check_emit ok "$CONTAINER_RUNTIME is usable"
    else
        _check_emit fail "$CONTAINER_RUNTIME not reachable — start the daemon or install it"
    fi
}

check_compose_tool() {
    if command -v "$DOCKER_COMPOSE" >/dev/null 2>&1; then
        _check_emit ok "$DOCKER_COMPOSE found"
    else
        _check_emit fail "$DOCKER_COMPOSE not found — install docker-compose or podman-compose"
    fi
}

check_node_npm() {
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        _check_emit ok "node $(node --version 2>/dev/null || echo '?')"
    else
        _check_emit fail "node/npm missing — install Node.js (dashboard needs it)"
    fi
}

check_ports() {
    local busy=0 summary=""
    local port
    for port in $MATRIX_CHECK_PORTS; do
        local line
        if command -v ss >/dev/null 2>&1; then
            line=$(ss -tlnp 2>/dev/null | grep -E ":${port}[[:space:]]" | head -1)
            if [[ -n "$line" ]]; then
                local pid cmd
                pid=$(grep -oE 'pid=[0-9]+' <<<"$line" | head -1 | cut -d= -f2)
                cmd=$(sed -n 's/.*users:((\("[^"]*"\).*/\1/p' <<<"$line")
                summary+="${port} in use by pid=${pid:-?} cmd=${cmd//\"/} ; "
                busy=1
            fi
        elif command -v lsof >/dev/null 2>&1; then
            local pids
            pids=$(lsof -ti:"$port" 2>/dev/null | tr '\n' ' ')
            if [[ -n "$pids" ]]; then
                summary+="${port} in use by pid=${pids// /,} ; "
                busy=1
            fi
        fi
    done
    if [[ "$busy" -eq 1 ]]; then
        _check_emit fail "port conflict: ${summary% ; } — free with: lsof -ti:<port> | xargs kill"
    else
        _check_emit ok "no conflicts on: ${MATRIX_CHECK_PORTS:-none}"
    fi
}

check_env_file() {
    if [[ ! -f "$MATRIX_ENV_FILE" ]]; then
        _check_emit fail ".env missing at $MATRIX_ENV_FILE — create it (DB credentials)"
        return 0
    fi
    local perms
    perms=$(stat -c '%a' "$MATRIX_ENV_FILE" 2>/dev/null || stat -f '%Lp' "$MATRIX_ENV_FILE" 2>/dev/null)
    if [[ "$perms" == "600" ]]; then
        _check_emit ok ".env present, perms 600"
    else
        _check_emit warn ".env perms $perms — fix with: chmod 600 $MATRIX_ENV_FILE"
    fi
}

check_disk_headroom() {
    # Threshold: 2 GiB free = 2*1024*1024 KiB
    local avail_kb
    avail_kb=$(eval "${MATRIX_DISK_CMD:-df -Pk "$PROJECT_ROOT"}" 2>/dev/null | awk 'NR==2 {print $4}')
    if [[ ! "$avail_kb" =~ ^[0-9]+$ ]]; then
        _check_emit warn "could not read free space (df output unexpected)"
        return 0
    fi
    if [[ "$avail_kb" -gt 2097152 ]]; then
        _check_emit ok "$((avail_kb / 1048576)) GiB free"
    else
        _check_emit fail "only ${avail_kb} KiB free (<2GiB) — clean docker: ./matrix clean"
    fi
}

check_hosts_reachability() {
    if grep -q '\.test' "$MATRIX_HOSTS_FILE" 2>/dev/null; then
        _check_emit ok ".test host entries present"
    else
        _check_emit warn "no .test entries in $MATRIX_HOSTS_FILE (optional; add for pretty domains)"
    fi
}

check_hooks_path() {
    local hp
    hp=$(git -C "$PROJECT_ROOT" config core.hooksPath 2>/dev/null || true)
    if [[ -n "$hp" ]]; then
        _check_emit ok "git hooks active at $hp"
    else
        _check_emit warn "core.hooksPath unset (.githooks inactive) — fix with: git config core.hooksPath .githooks"
    fi
}

DOCTOR_REGISTRY=(container_runtime compose_tool node_npm ports env_file disk_headroom hosts_reachability hooks_path)

# json_escape: safe inside double-quoted JSON strings.
_json_escape() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

cmd_doctor() {
    local json=false
    if [[ "${1:-}" == "--json" ]]; then
        json=true
    fi

    local entries="" any_fail=false
    local check out status detail
    for check in "${DOCTOR_REGISTRY[@]}"; do
        out=$("check_${check}")
        status=$(grep -oE 'status=(ok|warn|fail)' <<<"$out" | head -1 | cut -d= -f2)
        detail=$(grep -oE 'detail=.*' <<<"$out" | head -1 | cut -d= -f2-)
        [[ "$status" == "fail" ]] && any_fail=true
        if [[ "$json" == true ]]; then
            entries+="$(printf '{"check":"%s","status":"%s","detail":"%s"}' \
                "$check" "$status" "$(_json_escape <<<"$detail")"),"
        else
            printf "%-20s %-5s %s\n" "$check" "$status" "$detail"
        fi
    done

    if [[ "$json" == true ]]; then
        output_json "[${entries%,}]"
    fi

    [[ "$any_fail" == true ]] && return 1
    return 0
}