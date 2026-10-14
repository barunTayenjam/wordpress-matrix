#!/bin/bash
# Offline tests for the docker/compose stub scripts (tests/bash/bin/).
# These stubs are shared infrastructure for the Phase 1+ suites; this suite
# pins their contract so later phases can rely on it.
#
# Contract:
#   docker port <name> 80/tcp   -> "80/tcp -> 0.0.0.0:<hostport>" from portmap.txt
#   docker cp <src> <dst>       -> records "<dst>" appended to copied.txt
#   matrix-compose-stub restart <svc>... -> records each svc in restarted.txt

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

mkdir -p "$SANDBOX/bin" "$SANDBOX/logs"
cp "$REPO_ROOT/tests/bash/bin/docker" "$SANDBOX/bin/docker"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/matrix-compose-stub"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/docker-compose"
cp "$REPO_ROOT/tests/bash/bin/matrix-compose-stub" "$SANDBOX/bin/podman-compose"
cp "$REPO_ROOT/tests/bash/bin/stub-common.sh" "$SANDBOX/bin/stub-common.sh"
chmod +x "$SANDBOX/bin/"*
export PATH="$SANDBOX/bin:$PATH"
export STUB_DIR="$SANDBOX/state"
mkdir -p "$STUB_DIR/logs"

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

assert_contains() {
    local desc="$1" needle="$2" file="$3"
    if grep -qF -- "$needle" "$file" 2>/dev/null; then
        pass
    else
        fail "$desc — '$needle' not found in $file"
    fi
}

# --- T0.1: docker port maps container name to host port (contract pin) ------
printf 'nginx_alpha 8201\nwp_beta 8202\n' > "$STUB_DIR/portmap.txt"
assert_eq "T0.1 docker port output" \
    "80/tcp -> 0.0.0.0:8201" \
    "$(docker port nginx_alpha 80/tcp)"

# --- T0.2: docker cp records the destination --------------------------------
rm -f "$STUB_DIR/copied.txt"
docker cp /tmp/x container:/y
assert_contains "T0.2 docker cp recorded" "container:/y" "$STUB_DIR/copied.txt"

# --- T0.3: compose restart records the service ------------------------------
rm -f "$STUB_DIR/restarted.txt"
matrix-compose-stub restart nginx_alpha
assert_contains "T0.3 compose restart recorded" "nginx_alpha" "$STUB_DIR/restarted.txt"

# --- T0.4: docker restart records the container (parity with compose) -------
rm -f "$STUB_DIR/restarted.txt"
docker restart nginx_alpha
assert_contains "T0.4 docker restart recorded" "nginx_alpha" "$STUB_DIR/restarted.txt"

# --- T0.5: common.sh honors a preset DOCKER_COMPOSE (CI hosts have none) ----
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NCBIN="$(mktemp -d)"
ln -s "$(command -v dirname)" "$NCBIN/dirname"   # only external common.sh needs pre-detection
out=$(env -i PATH="$NCBIN" DOCKER_COMPOSE=my-compose "$(which bash)" -c \
    "source '$REPO_ROOT/scripts/common.sh' >/dev/null 2>&1; echo \"rc=\$? dc=\$DOCKER_COMPOSE\"")
rm -rf "$NCBIN"
assert_file=$(mktemp); printf '%s\n' "$out" > "$assert_file"
assert_contains "T0.5 preset DOCKER_COMPOSE survives common.sh (no compose on PATH)" "rc=0 dc=my-compose" "$assert_file"
rm -f "$assert_file"

echo ""
echo "stub tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
