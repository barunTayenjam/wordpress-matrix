#!/bin/bash
# Offline tests for the site state module (scripts/helpers.sh).
#
# Contract preserved from the pre-refactor baseline:
#   running = wp_<site> container is up (anchored name match, compose ps OR live ps)
#   port    = compose port, else live nginx port, else live wp port
#   php     = compose image only (empty when not defined there)
#   stack   = compose-derived, defaults to nginx
#   present = site service defined in docker-compose.yml
#
# Everything runs against stubs in tests/bash/bin — no Docker required.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

mkdir -p "$SANDBOX/bin" "$SANDBOX/logs"
cp "$REPO_ROOT/tests/bash/bin/docker" "$SANDBOX/bin/docker"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/matrix-compose-stub"
chmod +x "$SANDBOX/bin/"*
export PATH="$SANDBOX/bin:$PATH"
export STUB_DIR="$SANDBOX/state"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1"; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass
    else
        fail "$desc — expected '$expected', got '$actual'"
    fi
}

# load_helpers [fixture|none]
load_helpers() {
    local fixture="${1:-}"
    rm -f "$SANDBOX/docker-compose.yml"
    [[ "$fixture" != "none" && -n "$fixture" ]] && \
        cp "$REPO_ROOT/tests/bash/fixtures/$fixture" "$SANDBOX/docker-compose.yml"

    rm -rf "$STUB_DIR"
    mkdir -p "$STUB_DIR/logs"
    : > "$STUB_DIR/running.txt"
    : > "$STUB_DIR/all.txt"
    : > "$STUB_DIR/ports.txt"
    : > "$STUB_DIR/portmap.txt"
    : > "$STUB_DIR/compose-ps.txt"

    export PROJECT_ROOT="$SANDBOX"
    export COMPOSE_FILE="$SANDBOX/docker-compose.yml"
    export CONTAINER_RUNTIME="docker"
    export DOCKER_COMPOSE="matrix-compose-stub"

    mkdir -p "$SANDBOX/wp_alpha" "$SANDBOX/wp_beta"

    # shellcheck disable=SC1090,SC1091
    source "$REPO_ROOT/config/validation.sh"
    # shellcheck disable=SC1090,SC1091
    source "$REPO_ROOT/scripts/helpers.sh"
}

field() { # field <site> <key>
    site_state "$1" | sed -n "s/^$2=//p" | head -1
}

# --- T1: compose present + site present + running -----------------------------
load_helpers "docker-compose.yml"
printf 'wp_alpha\nnginx_alpha\nwp_db\n' > "$STUB_DIR/running.txt"
printf 'wp_alpha\nnginx_alpha\nwp_db\n' > "$STUB_DIR/compose-ps.txt"

assert_eq "T1 present"  "1"     "$(field alpha present)"
assert_eq "T1 running"  "1"     "$(field alpha running)"
assert_eq "T1 port"     "8201"  "$(field alpha port)"
assert_eq "T1 php"      "8.3"   "$(field alpha php)"
assert_eq "T1 stack"    "nginx" "$(field alpha stack)"

# --- T2: site in compose but stopped ------------------------------------------
load_helpers "docker-compose.yml"

assert_eq "T2 present"  "1"     "$(field alpha present)"
assert_eq "T2 running"  "0"     "$(field alpha running)"
assert_eq "T2 port"     "8201"  "$(field alpha port)"

# --- T3: stale compose (site missing from file) + container running live -----
load_helpers "docker-compose.yml"
printf 'wp_gamma\n' > "$STUB_DIR/running.txt"
printf 'wp_gamma 8299\n' > "$STUB_DIR/portmap.txt"

assert_eq "T3 present"  "0"     "$(field gamma present)"
assert_eq "T3 running"  "1"     "$(field gamma running)"
assert_eq "T3 port"     "8299"  "$(field gamma port)"
assert_eq "T3 php"      ""      "$(field gamma php)"
assert_eq "T3 stack"    "nginx" "$(field gamma stack)"

# --- T4: compose file missing entirely + container running --------------------
load_helpers "none"
printf 'wp_alpha\nnginx_alpha\n' > "$STUB_DIR/running.txt"
printf 'wp_alpha 8288\nnginx_alpha 8277\n' > "$STUB_DIR/portmap.txt"

assert_eq "T4 present"  "0"     "$(field alpha present)"
assert_eq "T4 running"  "1"     "$(field alpha running)"
assert_eq "T4 port"     "8277"  "$(field alpha port)"
assert_eq "T4 stack"    "nginx" "$(field alpha stack)"

# --- T5: site absent everywhere ----------------------------------------------
load_helpers "docker-compose.yml"

assert_eq "T5 present"  "0" "$(field gamma present)"
assert_eq "T5 running"  "0" "$(field gamma running)"
assert_eq "T5 port"     "" "$(field gamma port)"
assert_eq "T5 php"      "" "$(field gamma php)"
assert_eq "T5 stack"    "nginx" "$(field gamma stack)"

# --- T6: compose down but container up (live fallback) ------------------------
load_helpers "docker-compose.yml"
printf 'wp_alpha\n' > "$STUB_DIR/running.txt"
: > "$STUB_DIR/compose-ps.txt"

assert_eq "T6 running" "1" "$(field alpha running)"

# --- T7: apache stack from compose -------------------------------------------
load_helpers "docker-compose.yml"

assert_eq "T7 stack" "apache" "$(field beta stack)"
assert_eq "T7 php"   "8.1"    "$(field beta php)"
assert_eq "T7 port"  "8202"   "$(field beta port)"

# --- T8: anchored predicates (no prefix collisions) --------------------------
load_helpers "docker-compose.yml"

site_in_compose "alpha"   && assert_eq "T8 alpha in compose"    "ok" "ok" || assert_eq "T8 alpha in compose" "ok" "fail"
site_in_compose "gamma"   && assert_eq "T8 gamma not in compose" "fail" "fail" || assert_eq "T8 gamma not in compose" "ok" "ok"
site_in_compose "alph"    && assert_eq "T8 alph prefix no match" "fail" "fail" || assert_eq "T8 alph prefix no match" "ok" "ok"
site_in_compose "alphabet" && assert_eq "T8 alphabet no match" "fail" "fail" || assert_eq "T8 alphabet no match" "ok" "ok"

# --- T9: compose_or_container_running fallback -------------------------------
load_helpers "docker-compose.yml"
printf 'wp_alpha\n' > "$STUB_DIR/compose-ps.txt"
compose_or_container_running "wp_alpha" && assert_eq "T9 via compose ps" "ok" "ok" || assert_eq "T9 via compose ps" "ok" "fail"

load_helpers "docker-compose.yml"
printf 'wp_alpha\n' > "$STUB_DIR/running.txt"
: > "$STUB_DIR/compose-ps.txt"
compose_or_container_running "wp_alpha" && assert_eq "T9 via live ps" "ok" "ok" || assert_eq "T9 via live ps" "ok" "fail"

load_helpers "docker-compose.yml"
compose_or_container_running "wp_alpha" && assert_eq "T9 neither" "fail" "fail" || assert_eq "T9 neither" "ok" "ok"

# --- T10: compose_or_container_running is anchored ---------------------------
load_helpers "docker-compose.yml"
printf 'wp_alphabet\n' > "$STUB_DIR/compose-ps.txt"
printf 'wp_alphabet\n' > "$STUB_DIR/running.txt"
compose_or_container_running "wp_alpha" && assert_eq "T10 anchored" "fail" "fail" || assert_eq "T10 anchored" "ok" "ok"

echo ""
echo "site-state tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
