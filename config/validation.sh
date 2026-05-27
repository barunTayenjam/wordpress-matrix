#!/bin/bash
# config/validation.sh — Shared validation rules for wordpress-matrix
# Single source of truth for site naming, PHP versions, and reserved names.

RESERVED_NAMES=" frontend matrix db redis phpmyadmin nginx content mailpit mail "
SUPPORTED_PHP_VERSIONS="7.4 8.0 8.1 8.2 8.3"
DEFAULT_PHP_VERSION="8.3"
SITE_NAME_REGEX='^[a-zA-Z][a-zA-Z0-9_-]*$'

_error() {
    local msg="$1"
    if declare -F log_error &>/dev/null; then
        log_error "$msg"
    else
        echo "Error: $msg" >&2
    fi
}

validate_site_name() {
    local site_name="${1:-}"
    if [[ -z "$site_name" ]]; then
        _error "Site name required"
        return 1
    fi
    if [[ ! "$site_name" =~ $SITE_NAME_REGEX ]]; then
        _error "Invalid site name '$site_name'. Use a letter first, then letters, numbers, hyphens, or underscores."
        return 1
    fi
    local site_name_lc
    site_name_lc=$(echo "$site_name" | tr '[:upper:]' '[:lower:]')
    if [[ "$RESERVED_NAMES" == *" $site_name_lc "* ]]; then
        _error "'$site_name' is a reserved site name"
        return 1
    fi
}

validate_php_version() {
    local version="${1:-}"
    case "$version" in
        7.4|8.0|8.1|8.2|8.3) return 0 ;;
        *)
            _error "Invalid PHP version: $version. Supported: $SUPPORTED_PHP_VERSIONS"
            return 1
            ;;
    esac
}

sanitize_sql_identifier() {
    local input="${1:-}"
    echo "$input" | tr -cd 'a-zA-Z0-9_-'
}

validation_json() {
    local json
    json=$(cat <<ENDJSON
{
  "reservedNames": [$(for n in $RESERVED_NAMES; do printf '"%s",' "$n"; done | sed 's/,$//')],
  "supportedPhpVersions": [$(for v in $SUPPORTED_PHP_VERSIONS; do printf '"%s",' "$v"; done | sed 's/,$//')],
  "defaultPhpVersion": "$DEFAULT_PHP_VERSION",
  "siteNameRegex": "$SITE_NAME_REGEX"
}
ENDJSON
)
    echo "$json"
}
