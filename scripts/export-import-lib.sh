#!/bin/bash
# Export/import bundle library for wordpress-matrix (FEATURES-PLAN.md Phase 6).
# Bundle layout (tar.gz, manifest LAST member):
#   manifest.json {site, php_version, stack, ports, wp_version, db_dump_sha256,
#                  table_prefix, multisite, created_at, matrix_version}
#   files/   site dir contents (excludes logs/, .git)
#   db/site.sql.gz
# DB seams (re-definable for offline tests): dump_site_db, db_exec_root,
# db_import_dump.

set -uo pipefail

# --- DB seams (defaults; tests override) ---
dump_site_db() {
    local site="$1"
    $CONTAINER_RUNTIME exec -e MYSQL_PWD="${MYSQL_PASSWORD:-wp_password}" wp_db \
        mysqldump --no-tablespaces -u"${MYSQL_USER:-wp_user}" "${site}_db"
}
db_exec_root() {
    $CONTAINER_RUNTIME exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-root}" wp_db \
        mysql -u root -e "$*"
}
db_import_dump() {
    local dump_file="$1" db_name="$2"
    gunzip -c "$dump_file" | $CONTAINER_RUNTIME exec -i -e MYSQL_PWD="${MYSQL_PASSWORD:-wp_password}" wp_db \
        mysql -u"${MYSQL_USER:-wp_user}" "$db_name"
}

# --- manifest helpers (REFACTOR target: restore may adopt later) ---
bundle_manifest_field() {
    # Usage: bundle_manifest_field <manifest-file> <key> → value (string only)
    sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" "$1" | head -1
}
bundle_manifest_bool() {
    grep -q "\"$2\":true" "$1" && echo true || echo false
}
bundle_manifest_validate() {
    local mf="$1"
    [[ -s "$mf" ]] || return 1
    local required site
    # db_dump_sha256 required only for db-backed types (grav carries none)
    for required in site; do
        [[ -n "$(bundle_manifest_field "$mf" "$required")" ]] || return 1
    done
    local type
    type=$(bundle_manifest_field "$mf" type)
    [[ -z "$type" ]] && type="wp"
    if site_type_uses_db "$type"; then
        [[ -n "$(bundle_manifest_field "$mf" db_dump_sha256)" ]] || return 1
    fi
    return 0
}

_site_table_prefix() {
    local site="$1"
    sed -n "s/.*\$table_prefix = '\([^']*\)'.*/\1/p" "$PROJECT_ROOT/wp_$site/wp-config.php" 2>/dev/null
}

_site_stack() {
    local site="$1"
    cat "$PROJECT_ROOT/wp_$site/.matrix-stack" 2>/dev/null || echo "nginx"
}

_matrix_version() {
    git -C "$PROJECT_ROOT" describe --tags --always 2>/dev/null || echo "dev"
}

# export_site <site> [--out FILE] [--json]
export_site() {
    local site="${1:-}"; shift || true
    local out="" json=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --out) out="$2"; shift 2 ;;
            --out=*) out="${1#*=}"; shift ;;
            --json) json=true; shift ;;
            *) shift ;;
        esac
    done
    if [[ -z "$site" ]] || ! site_exists "$site"; then
        error_json "EXPORT_SITE_MISSING" "Site '$site' does not exist"
        return 1
    fi

    [[ -z "$out" ]] && out="$PROJECT_ROOT/backups/${site}-$(date +%Y%m%d-%H%M%S)-bundle.tar.gz"
    mkdir -p "$(dirname "$out")"

    local tmp
    tmp=$(mktemp -d)
    # Double quotes bake the value in now: with single quotes the RETURN trap
    # would expand $tmp after the local goes out of scope and die on set -u.
    trap "rm -rf '$tmp'" RETURN

    # files/: site dir minus logs/ and .git
    mkdir -p "$tmp/files"
    cp -a "$PROJECT_ROOT/wp_$site/." "$tmp/files/" 2>/dev/null || true
    rm -rf "$tmp/files/logs" "$tmp/files/.git"

    # db/: dump + gzip + sha (db-backed types only — grav exports files only)
    local sha="" type
    type=$(get_site_type "$site")
    if site_type_uses_db "$type"; then
        mkdir -p "$tmp/db"
        dump_site_db "$site" > "$tmp/db/site.sql" 2>/dev/null || \
            log_warning "DB dump empty or failed — bundle carries schema only"
        gzip -f "$tmp/db/site.sql"
        sha=$(sha256sum "$tmp/db/site.sql.gz" | cut -d' ' -f1)
    fi

    # manifest.json (written last into tar: deterministic member order)
    local wp_ver php_ver port
    wp_ver=$(site_wp_version "$site")
    php_ver=$(site_state "$site" | grep '^php=' | cut -d= -f2)
    [[ -z "$php_ver" ]] && php_ver="$DEFAULT_PHP_VERSION"
    port=$(get_site_port "$site")
    cat > "$tmp/manifest.json" << EOF
{"site":"$site","type":"$type","php_version":"$php_ver","stack":"$(_site_stack "$site")","ports":"${port:-}","wp_version":"${wp_ver:-}","db_dump_sha256":"$sha","table_prefix":"$(_site_table_prefix "$site")","multisite":$(site_is_multisite "$site" && echo true || echo false),"created_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","matrix_version":"$(_matrix_version)"}
EOF

    if site_type_uses_db "$type"; then
        tar -czf "$out" -C "$tmp" files db manifest.json
    else
        tar -czf "$out" -C "$tmp" files manifest.json
    fi

    if [[ "$json" == true ]]; then
        output_json "{\"success\":true,\"site\":\"$site\",\"bundle\":\"$out\",\"db_dump_sha256\":\"$sha\"}"
    else
        log_success "Bundle written: $out"
    fi
    log_activity "EXPORT" "$site" "bundle $out"
    return 0
}

# import_site <bundle.tar.gz> <new-site> [--yes] [--json]
import_site() {
    local bundle="${1:-}" new_site="${2:-}"; shift 2 || true
    local force=false json=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes) force=true; shift ;;
            --json) json=true; shift ;;
            *) shift ;;
        esac
    done

    if [[ ! -f "$bundle" ]]; then
        error_json "IMPORT_MANIFEST_INVALID" "Bundle not found: $bundle"
        return 1
    fi
    validate_site_name "$new_site" || {
        error_json "IMPORT_MANIFEST_INVALID" "Invalid new site name: $new_site"
        return 1
    }
    if site_exists "$new_site" && [[ "$force" != true ]]; then
        error_json "IMPORT_NAME_TAKEN" "Site '$new_site' already exists (use --yes to overwrite)"
        return 1
    fi

    local tmp
    tmp=$(mktemp -d)
    trap "rm -rf '$tmp'" RETURN
    tar -xzf "$bundle" -C "$tmp" 2>/dev/null || {
        error_json "IMPORT_MANIFEST_INVALID" "Bundle is not a valid tar.gz: $bundle"
        return 1
    }

    local mf="$tmp/manifest.json"
    bundle_manifest_validate "$mf" || {
        error_json "IMPORT_MANIFEST_INVALID" "Missing or invalid manifest.json in bundle"
        return 1
    }
    local old_site sha php_ver stack type
    old_site=$(bundle_manifest_field "$mf" site)
    type=$(bundle_manifest_field "$mf" type)
    [[ -z "$type" ]] && type="wp"
    sha=$(bundle_manifest_field "$mf" db_dump_sha256)
    php_ver=$(bundle_manifest_field "$mf" php_version)
    stack=$(bundle_manifest_field "$mf" stack)
    [[ -z "$php_ver" ]] && php_ver="$DEFAULT_PHP_VERSION"
    [[ -z "$stack" ]] && stack="nginx"

    # NOTE: the sha probe must only run for db-backed types. For grav there is
    # no db member at all; an unconditional `$(sha256sum missing-file ...)`
    # returns non-zero and aborts the whole import under the caller's set -e
    # (found live: grav import exited 1 with zero output).
    local actual_sha=""
    if site_type_uses_db "$type"; then
        actual_sha=$(sha256sum "$tmp/db/site.sql.gz" 2>/dev/null | cut -d' ' -f1 || true)
    fi
    if site_type_uses_db "$type" && [[ "$actual_sha" != "$sha" ]]; then
        error_json "IMPORT_SHA_MISMATCH" "DB dump sha mismatch (manifest $sha, actual ${actual_sha:-none})"
        return 1
    fi

    # Skeleton (compose+nginx+db grant) via existing create path, minus download.
    # --yes overwrite: files restored over existing site; skeleton steps are
    # idempotent (CREATE IF NOT EXISTS, conf regenerated).
    create_site "$new_site" --type="$type" --php-version="$php_ver" --stack="$stack" --skip-download >/dev/null 2>&1

    # Restore files (overwrites generated wp-config; preserves table_prefix)
    mkdir -p "$PROJECT_ROOT/wp_$new_site"
    cp -a "$tmp/files/." "$PROJECT_ROOT/wp_$new_site/"

    # Non-wp: repoint the restored config at the new site's own database.
    if [[ "$type" != "wp" ]]; then
        repoint_clone_env "$PROJECT_ROOT/wp_$new_site" "$old_site" "$new_site"
    fi

    # DB: create + import (db-backed types only)
    if site_type_uses_db "$type"; then
        db_exec_root "CREATE DATABASE IF NOT EXISTS \`${new_site}_db\`; GRANT ALL PRIVILEGES ON \`${new_site}_db\`.* TO '${MYSQL_USER:-wp_user}'@'%'; FLUSH PRIVILEGES;"
        db_import_dump "$tmp/db/site.sql.gz" "${new_site}_db"
    fi

    # URL remap: dry-run print (no mutation, per Phase 6 scope)
    local old_port new_port
    old_port=$(bundle_manifest_field "$mf" ports)
    new_port=$(get_site_port "$new_site")
    echo "search-replace (dry-run): http://${HOST_IP:-localhost}:${old_port:-?} → http://${HOST_IP:-localhost}:${new_port:-?}"

    if [[ "$json" == true ]]; then
        output_json "{\"success\":true,\"site\":\"$new_site\",\"imported_from\":\"$old_site\"}"
    else
        log_success "Imported '$old_site' → '$new_site'"
    fi
    log_activity "IMPORT" "$new_site" "from bundle $bundle (source $old_site)"
    return 0
}