#!/bin/bash
# Share (tunnel) library for wordpress-matrix (FEATURES-PLAN.md Phase 4).
# Wraps cloudflared / ngrok / bore to expose a running site publicly.
# share_site blocks in the foreground; INT/TERM/EXIT traps kill the provider
# child and remove its pidfile.

set -uo pipefail

# Echoes cloudflared|ngrok|bore|"" — first provider found on PATH.
# MATRIX_SHARE_PATH (colon-separated dirs) overrides PATH for discovery, so
# callers/tests can control visibility without mutating PATH itself.
detect_share_provider() {
    local bin dir
    local search_path="${MATRIX_SHARE_PATH:-$PATH}"
    for bin in cloudflared ngrok bore; do
        if [[ -z "$MATRIX_SHARE_PATH" ]]; then
            command -v "$bin" >/dev/null 2>&1 && { echo "$bin"; return 0; }
        else
            while IFS= read -r dir; do
                [[ -x "$dir/$bin" ]] && { echo "$bin"; return 0; }
            done <<< "$(tr ':' '\n' <<< "$search_path")"
        fi
    done
    echo ""
}

# Extracts the public URL for <provider> from its <logfile> (empty if absent).
provider_url_from_log() {
    local provider="${1:-}" logfile="${2:-}"
    case "$provider" in
        cloudflared)
            grep -m1 -oE 'https?://[^[:space:]]+\.trycloudflare\.com' "$logfile" 2>/dev/null
            ;;
        ngrok)
            grep -m1 -oE 'https?://[^[:space:]]+\.(ngrok\.io|ngrok-free\.app)' "$logfile" 2>/dev/null
            ;;
        bore)
            grep -m1 -oE 'https?://[^[:space:]]+:[0-9]+' "$logfile" 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Poll a logfile until a URL appears (or timeout passes). Echoes URL or "".
# ponytail: fixed 0.5s cadence, 30s cap — fine for 3 providers; switch to
# provider notification APIs if timeouts ever bite.
wait_for_url() {
    local logfile="$1" provider="$2" deadline=$((SECONDS + 30)) url=""
    while [[ $SECONDS -lt $deadline ]]; do
        url=$(provider_url_from_log "$provider" "$logfile")
        [[ -n "$url" ]] && { echo "$url"; return 0; }
        sleep 0.5
    done
    echo ""
}

# share_site <site> [--provider=P] [--yes] [--json]
share_site() {
    local site="${1:-}"; shift || true
    local provider="" yes_flag=false json=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --provider=*) provider="${1#*=}"; shift ;;
            --yes) yes_flag=true; shift ;;
            --json) json=true; shift ;;
            *) shift ;;
        esac
    done

    if [[ -z "$site" ]]; then
        error_json "SHARE_SITE_NOT_RUNNING" "Site name required"
        return 1
    fi
    if ! site_state "$site" | grep -q '^running=1'; then
        error_json "SHARE_SITE_NOT_RUNNING" "Site '$site' is not running"
        return 1
    fi

    [[ -z "$provider" ]] && provider=$(detect_share_provider)
    if [[ -z "$provider" ]]; then
        error_json "SHARE_NO_PROVIDER" "No share provider found (cloudflared, ngrok, or bore). Install one or pass --provider=P."
        return 1
    fi

    # Exposure confirmation: --yes prints the warning once and proceeds; a tty
    # gets a prompt; a non-tty without --yes refuses.
    if [[ "$yes_flag" != true ]]; then
        if [[ -t 0 ]]; then
            echo "Warning: '$site' will be publicly reachable via the tunnel URL."
            read -r -p "Proceed? [y/N] " ans || ans="n"
            [[ "$ans" == "y" || "$ans" == "Y" ]] || { log_info "Share aborted"; return 1; }
        else
            error_json "SHARE_CONFIRM_REQUIRED" "Public exposure needs --yes (no tty to confirm)"
            return 1
        fi
    else
        echo "Warning: '$site' will be publicly reachable via the tunnel URL."
    fi

    local port
    port=$(get_site_port "$site")
    [[ -z "$port" ]] && port="80"

    local logfile="/tmp/matrix-share-${site}.log"
    local pidfile="/tmp/matrix-share-${site}.pid"

    case "$provider" in
        cloudflared) cloudflared tunnel --url "http://localhost:${port}" > "$logfile" 2>&1 & ;;
        ngrok)       ngrok http "$port" --log stdout > "$logfile" 2>&1 & ;;
        bore)        bore local "$port" --skip-autodetect > "$logfile" 2>&1 & ;;
    esac
    local pid=$!
    echo "$pid" > "$pidfile"

    # Cleanup armed immediately: Ctrl-C (INT) or external TERM (timeout)
    # must kill the child and drop the pidfile even mid-URL-wait.
    trap 'kill "$pid" 2>/dev/null; rm -f "$pidfile"; exit 1' INT TERM EXIT
    log_activity "SHARE_START" "$site" "provider=$provider port=$port"

    local url
    url=$(wait_for_url "$logfile" "$provider")

    if [[ -n "$url" ]]; then
        if [[ "$json" == true ]]; then
            output_json "{\"provider\":\"$provider\",\"url\":\"$url\"}"
        else
            echo "Public URL: $url"
        fi
    else
        log_warning "No URL detected within 30s — provider still starting; Ctrl-C to stop"
    fi

    # Block in the foreground until interrupted (documented: --json also keeps
    # the process alive; the trap does the cleanup).
    wait "$pid" 2>/dev/null || true
    trap - INT TERM EXIT
    rm -f "$pidfile"
    log_activity "SHARE_STOP" "$site" "provider=$provider"
}