#!/bin/bash
# Ops library for wordpress-matrix (FEATURES-PLAN.md Phase 8).
# Scheduled backups via marker-comment blocks:
#   .cron/<site>.cron      — schedule definition for one site
#   MATRIX_CRONTAB_FILE    — crontab being managed (test seam; production
#                            pipes through `crontab -` instead)
# All edits are block-scoped: foreign crontab lines are never touched
# (risk register: "Cron edits damage user crontab → marker-block diff only").

set -uo pipefail

# Translate a symbolic interval to a cron timespec.
_interval_to_cron() {
    case "${1:-daily}" in
        hourly)  echo "0 * * * *" ;;
        daily)   echo "0 2 * * *" ;;
        weekly)  echo "0 3 * * 0" ;;
        monthly) echo "0 4 1 * *" ;;
        *)       echo "0 2 * * *" ;;
    esac
}

# schedule_backup <site> <interval> <retention>
# Rewrites the site's .cron/<site>.cron block atomically — idempotent, and a
# reschedule replaces the block rather than appending a second one.
schedule_backup() {
    local site="${1:-}" interval="${2:-daily}" retention="${3:-7}"
    [[ -z "$site" ]] && return 1
    local cron_file="$PROJECT_ROOT/.cron/${site}.cron"
    mkdir -p "$(dirname "$cron_file")"
    local tmp="${cron_file}.tmp"
    {
        echo "# BEGIN matrix ${site}"
        echo "# schedule: ${interval}"
        echo "# retention: ${retention}"
        echo "$(_interval_to_cron "$interval") $PROJECT_ROOT/scripts/backup.sh ${site} >/dev/null 2>&1"
        echo "# END matrix ${site}"
    } > "$tmp"
    mv "$tmp" "$cron_file"
    log_activity "SCHEDULE" "$site" "interval=$interval retention=$retention"
}

# _crontab_strip_block <file> <site> — print file minus the site's marker block.
_crontab_strip_block() {
    awk -v begin="# BEGIN matrix ${2}" -v end="# END matrix ${2}" '
        $0 == begin { skip = 1; next }
        $0 == end   { skip = 0; next }
        skip == 0     { print }
    ' "$1"
}

# cron_install <site> — sync .cron/<site>.cron block into the crontab.
# Removes any existing block for the site first (idempotent; reinstall after
# a reschedule picks up the new definition). Foreign lines untouched.
cron_install() {
    local site="${1:-}"
    [[ -z "$site" ]] && return 1
    local crontab="${MATRIX_CRONTAB_FILE:-}"
    [[ -n "$crontab" ]] || { log_error "MATRIX_CRONTAB_FILE not set"; return 1; }
    local cron_file="$PROJECT_ROOT/.cron/${site}.cron"
    [[ -f "$cron_file" ]] || { log_error "No schedule for '$site' — run: matrix backup $site --schedule=<interval>"; return 1; }
    touch "$crontab"
    _crontab_strip_block "$crontab" "$site" > "${crontab}.tmp"
    cat "$cron_file" >> "${crontab}.tmp"
    mv "${crontab}.tmp" "$crontab"
    log_activity "CRON_INSTALL" "$site" "block installed"
}

# cron_remove <site> — drop the site's marker block; foreign lines preserved.
cron_remove() {
    local site="${1:-}"
    [[ -z "$site" ]] && return 1
    local crontab="${MATRIX_CRONTAB_FILE:-}"
    [[ -n "$crontab" ]] || { log_error "MATRIX_CRONTAB_FILE not set"; return 1; }
    [[ -f "$crontab" ]] || return 0
    _crontab_strip_block "$crontab" "$site" > "${crontab}.tmp"
    mv "${crontab}.tmp" "$crontab"
    log_activity "CRON_REMOVE" "$site" "block removed"
}

# prune_backups <dir> <keep-N> — keep the N newest .tar.gz, remove the rest
# oldest-first, and record the prune in the activity log.
prune_backups() {
    local dir="${1:-}" keep="${2:-3}"
    [[ -d "$dir" ]] || return 0
    local files
    files=$(ls -1t "$dir"/*.tar.gz 2>/dev/null || true)
    [[ -z "$files" ]] && return 0
    local count
    count=$(wc -l <<<"$files")
    local removed=0
    if [[ "$count" -gt "$keep" ]]; then
        local to_remove=$((count - keep)) f
        # files is newest-first; oldest are at the END → remove from bottom
        for ((i = count; i > keep; i--)); do
            f=$(sed -n "${i}p" <<<"$files")
            rm -f "$f" && removed=$((removed + 1))
        done
    fi
    echo "PRUNE kept=${keep} removed=${removed} of=${count} dir=${dir} at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$ACTIVITY_LOG"
}

# cmd_backup — matrix backup dispatcher: schedule flags route here, everything
# else delegates to scripts/backup.sh unchanged.
cmd_backup() {
    local site="${1:-}" interval="" retention="" schedule_only=false
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --schedule) interval="$2"; shift 2 ;;
            --schedule=*) interval="${1#*=}"; shift ;;
            --retention) retention="$2"; shift 2 ;;
            --retention=*) retention="${1#*=}"; shift ;;
            *) shift ;;
        esac
    done
    if [[ -n "$interval" ]]; then
        schedule_backup "$site" "$interval" "${retention:-7}" && cron_install "$site"
    else
        # on-demand backup: existing behavior, then prune per retention
        "$PROJECT_ROOT/scripts/backup.sh" "$site"
        if [[ -n "$retention" ]]; then
            prune_backups "$PROJECT_ROOT/backups" "$retention"
        fi
    fi
}