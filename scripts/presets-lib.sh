#!/bin/bash
# Presets library for sitematrix.
# Loads preset definitions from config/presets/*.sh files.
# Each preset file must define preset_description() and may define:
#   preset_plugins(), preset_theme(), preset_wp_config(), preset_post_install()

set -uo pipefail

# Default presets directory (can be overridden via MATRIX_PRESETS_DIR env)
MATRIX_PRESETS_DIR="${MATRIX_PRESETS_DIR:-$PROJECT_ROOT/config/presets}"

# Validate a preset name: alphanumeric + dash + underscore, no path traversal.
# Returns 0 if valid, 1 otherwise.
validate_preset_name() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        return 1
    fi
    # Must match site-name-like pattern, no slashes or dots
    if [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    fi
    return 1
}

# List all available presets with their descriptions.
# Usage: list_presets [--json]
list_presets() {
    local json_mode=0
    [[ "${1:-}" == "--json" ]] && json_mode=1

    local presets_dir="$MATRIX_PRESETS_DIR"
    if [[ ! -d "$presets_dir" ]]; then
        if [[ "$json_mode" -eq 1 ]]; then
            output_json '{"success":true,"presets":[]}'
            return 0
        fi
        log_warning "No presets directory at $presets_dir"
        return 0
    fi

    local names=() descs=()
    local file name desc
    for file in "$presets_dir"/*.sh; do
        [[ -f "$file" ]] || continue
        name=$(basename "$file" .sh)
        desc=$( ( source "$file" 2>/dev/null && preset_description 2>/dev/null ) 2>/dev/null || true )
        names+=("$name")
        descs+=("${desc//\"/\\\"}")
    done

    if [[ "$json_mode" -eq 1 ]]; then
        local rows=""
        local i
        for i in "${!names[@]}"; do
            [[ -n "$rows" ]] && rows+=","
            rows+="{\"name\":\"${names[$i]}\",\"description\":\"${descs[$i]}\"}"
        done
        output_json "{\"success\":true,\"presets\":[$rows]}"
        return 0
    fi

    printf "%-15s %-50s\n" "Preset" "Description"
    echo "────────────────────────────────────────────────────────────────────────"
    for i in "${!names[@]}"; do
        printf "%-15s %-50s\n" "${names[$i]}" "${descs[$i]}"
    done
}

# Apply a preset to a site.
# Usage: apply_preset <site> <preset>
apply_preset() {
    local site="${1:-}"
    local preset="${2:-}"

    if [[ -z "$site" || -z "$preset" ]]; then
        error_json "PRESET_INVALID_NAME" "Site and preset name required"
        return 1
    fi

    # Validate preset name
    if ! validate_preset_name "$preset"; then
        error_json "PRESET_INVALID_NAME" "Invalid preset name: $preset (alphanumeric, dash, underscore only)"
        return 1
    fi

    local preset_file="$MATRIX_PRESETS_DIR/$preset.sh"
    if [[ ! -f "$preset_file" ]]; then
        # List available for error message
        local available=()
        if [[ -d "$MATRIX_PRESETS_DIR" ]]; then
            for f in "$MATRIX_PRESETS_DIR"/*.sh; do
                [[ -f "$f" ]] && available+=("$(basename "$f" .sh)")
            done
        fi
        error_json "PRESET_UNKNOWN" "Unknown preset: $preset. Available: ${available[*]:-none}"
        return 1
    fi

    # Source the preset file (validated name ensures no path traversal)
    # Clear any hooks left over from a previously sourced preset.
    unset -f preset_description preset_plugins preset_theme preset_wp_config preset_post_install 2>/dev/null || true
    # shellcheck disable=SC1090
    source "$preset_file"

    local site_dir="$PROJECT_ROOT/wp_$site"
    local plugins_dir="$site_dir/wp-content/plugins"
    local themes_dir="$site_dir/wp-content/themes"
    local wp_config="$site_dir/wp-config.php"

    mkdir -p "$plugins_dir" "$themes_dir"

    export PRESET_SITE="$site"

    # Plugins
    if declare -f preset_plugins >/dev/null; then
        local plugins
        plugins=$(preset_plugins 2>/dev/null || true)
        if [[ -n "$plugins" ]]; then
            log_info "Installing preset plugins: $plugins"
            for plugin in $plugins; do
                run_wp_cli "$site" plugin install "$plugin" --activate --allow-root 2>/dev/null || \
                    log_warning "$plugin installation may have failed"
            done
        fi
    fi

    # Theme
    if declare -f preset_theme >/dev/null; then
        local theme
        theme=$(preset_theme 2>/dev/null || true)
        if [[ -n "$theme" ]]; then
            log_info "Installing preset theme: $theme"
            run_wp_cli "$site" theme install "$theme" --activate --allow-root 2>/dev/null || \
                log_warning "$theme installation may have failed"
        fi
    fi

    # wp-config defines
    if declare -f preset_wp_config >/dev/null; then
        local configs
        configs=$(preset_wp_config 2>/dev/null || true)
        if [[ -n "$configs" && -f "$wp_config" ]]; then
            local key val
            while IFS='=' read -r key val; do
                [[ -z "$key" ]] && continue
                if ! grep -q "define( '$key'," "$wp_config"; then
                    cat >> "$wp_config" << EOF

define( '$key', '$val' );
EOF
                fi
            done <<< "$configs"
        fi
    fi

    # Post-install hook
    if declare -f preset_post_install >/dev/null; then
        log_info "Running preset post-install hook..."
        preset_post_install 2>/dev/null || \
            log_warning "Preset post-install hook may have failed"
    fi

    log_success "Preset '$preset' applied to '$site'"
    return 0
}

# Helper presets can call to install multiple plugins uniformly.
# Usage: preset_install_plugins <site> <plugin1> [plugin2 ...]
preset_install_plugins() {
    local site="${1:-}"; shift
    local plugin
    for plugin in "$@"; do
        run_wp_cli "$site" plugin install "$plugin" --activate --allow-root 2>/dev/null || \
            log_warning "$plugin installation may have failed"
    done
}