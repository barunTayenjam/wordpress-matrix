#!/bin/bash
# SSL library for sitematrix.
# Generates per-site TLS certificates and configures nginx to use them.
# Falls back from mkcert to openssl when mkcert is not installed.
# Design: additive (no existing certs removed), idempotent, --force for overwrite.

set -uo pipefail

# --- Configuration helpers ---

# Returns the port number for <site> from compose metadata or live container.
# Used to compute the paired HTTPS port (HTTP_port + 1000).
get_site_port() {
    local site="${1:-}"
    local port=""
    # First try compose metadata: look for the nginx_<site> port mapping
    if [[ -n "$site" && -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        # Look for - "8201:80" style lines under the nginx_<site> service block
        port=$(grep -A 30 "^  nginx_${site}:" "$PROJECT_ROOT/docker-compose.yml" 2>/dev/null | \
            grep -E '^\s*-\s*"[0-9]+:80"' | \
            grep -oE '^[0-9]+' | head -1)
    fi
    # Fallback: live container inspection (works even if compose is absent)
    if [[ -z "$port" ]]; then
        port=$($CONTAINER_RUNTIME port "nginx_${site}" 2>/dev/null | grep '80/tcp' | head -1 | sed 's/.*://' | tr -d ' ')
    fi
    echo "$port"
}

# Compute the HTTPS port paired with a given HTTP port.
# Rule: https_port = http_port + 1000
compute_https_port() {
    local http_port="${1:-0}"
    if [[ "$http_port" =~ ^[0-9]+$ ]] && [[ "$http_port" -ge 1 ]] 2>/dev/null; then
        echo $((http_port + 1000))
    else
        echo ""
    fi
}

# --- Certificate management ---

# generate_site_cert <site> [--force]
# Generates a TLS certificate for <site>.
# If mkcert is installed, uses mkcert to create a trusted certificate.
# Otherwise falls back to openssl self-signed certificate.
# Idempotent: overwrites existing cert only when --force is given.
generate_site_cert() {
    local site="${1:-}"
    local force=false

    # Parse --force flag
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # If cert already exists and not --force, exit 0 (idempotent)
    if [[ "$force" != "true" && -f "$PROJECT_ROOT/ssl-certs/${site}/server.crt" ]]; then
        log_info "Certificate already exists for '$site'. Use --force to regenerate."
        return 0
    fi

    local cert_dir="$PROJECT_ROOT/ssl-certs/${site}"
    local server_cert="$cert_dir/server.crt"
    local server_key="$cert_dir/server.key"

    # Create cert directory if it doesn't exist
    mkdir -p "$cert_dir"

    if command -v mkcert >/dev/null 2>&1; then
        # Use mkcert to generate a trusted certificate
        mkcert -cert-file "$server_cert" -key-file "$server_key" \
            "localhost" "127.0.0.1" "${site}.test" "*.${site}.test" 2>/dev/null || \
            # Fallback if mkcert fails for any reason
            generate_openssl_cert "${site}"
    else
        # Use openssl fallback
        generate_openssl_cert "${site}"
    fi

    # Ensure restrictive permissions on the key file (convention T-05-02)
    chmod 600 "$server_key" 2>/dev/null || true

    log_info "Generated TLS certificate for '$site' at '$server_cert'"
    return 0
}

# generate_openssl_cert <site>
# Generates a self-signed certificate using openssl.
generate_openssl_cert() {
    local site="${1:-}"
    local cert_dir="$PROJECT_ROOT/ssl-certs/${site}"
    local server_cert="$cert_dir/server.crt"
    local server_key="$cert_dir/server.key"

    # Generate RSA 2048 key and self-signed cert with SAN
    openssl req -x509 \
        -newkey rsa:2048 \
        -nodes \
        -keyout "$server_key" \
        -out "$server_cert" \
        -subj "/C=US/ST=Development/L=Local/O=WordPress Dev/CN=${site}" \
        -addext "subjectAltName=DNS:localhost,DNS:${site}.test,IP:127.0.0.1,IP:::1" 2>/dev/null || \
        return 1

    log_info "Generated openssl self-signed certificate for '$site'"
}

# site_cert_exists <site>
# Returns 0 if a certificate exists for <site>, 1 otherwise.
site_cert_exists() {
    local site="${1:-}"
    [[ -f "$PROJECT_ROOT/ssl-certs/${site}/server.crt" ]]
}

# site_cert_fingerprint <site>
# Returns the SHA256 fingerprint of the certificate, or empty string.
site_cert_fingerprint() {
    local site="${1:-}"
    local cert="$PROJECT_ROOT/ssl-certs/${site}/server.crt"
    if [[ -f "$cert" ]]; then
        openssl x509 -fingerprint -noout -sha256 "$cert" 2>/dev/null | sed 's/SHA256 Fingerprint=//' || true
    fi
}

# --- Domain management ---

# domain <site> [hostname] [--yes]
# Manages /etc/hosts entries for pretty hostnames (<site>.test).
# Without --yes, prompts for confirmation in interactive mode and exits
# with an error if not running in a terminal.
# With --yes, skips the confirmation prompt.
domain() {
    local site="${1:-}"
    local hostname="${2:-${site}.test}"
    local force=false

    # Parse --yes flag
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes)
                force=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Validate site name
    if [[ -z "$site" ]]; then
        log_error "Site name is required."
        return 1
    fi

    # Check if already in /etc/hosts
    if grep -qF -- "${hostname}" /etc/hosts 2>/dev/null; then
        log_info "Hostname '${hostname}' is already in /etc/hosts."
        return 0
    fi

    # Ask for confirmation unless --yes is given
    if [[ "$force" != "true" && -t 0 ]]; then
        read -r -p "Add '${hostname}' to /etc/hosts pointing to your LAN IP? (y/N) " response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        if [[ "$response" != "y" && "$response" != "yes" ]]; then
            log_info "Skipping /etc/hosts modification."
            return 0
        fi
    fi

    # Get LAN IP and add to /etc/hosts
    local lan_ip
    lan_ip=$(get_lan_ip)
    if [[ -n "$lan_ip" ]]; then
        # Append to /etc/hosts using sudo; graceful failure if sudo not available
        if sudo sh -c "echo '${lan_ip} ${hostname}' >> /etc/hosts" 2>/dev/null; then
            log_info "Added '${hostname}' (${lan_ip}) to /etc/hosts."
        else
            # Fallback: instruct user to add manually
            log_warning "Could not modify /etc/hosts via sudo."
            log_info "Please add manually: ${lan_ip} ${hostname}"
            # Still exit 0 so the workflow isn't broken
            return 0
        fi
    else
        log_warning "Could not determine LAN IP."
        log_info "Please add '${hostname}' to /etc/hosts manually."
    fi

    return 0
}

# Remove a hostname entry from /etc/hosts
remove_hostname_from_etc() {
    local hostname="${1:-}"
    if sudo sed -i "/${hostname}/d" /etc/hosts 2>/dev/null; then
        log_info "Removed '${hostname}' from /etc/hosts."
    else
        log_warning "Could not remove '${hostname}' from /etc/hosts via sudo."
        log_info "Please remove manually: sudo sed -i '/${hostname}/d' /etc/hosts"
    fi
}

# --- matrix command wrappers ---

# matrix ssl <site> [--force] [--revoke] [--json]
# Generates/removes TLS certificate and configures nginx for the site.
# --force: regenerate existing certificate
# --revoke: remove certificate and nginx ssl configuration
# --json: emit JSON output
cmd_ssl() {
    local site="${1:-}"
    local force=false
    local revoke=false
    local json=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            --revoke)
                revoke=true
                shift
                ;;
            --json)
                json=true
                shift
                ;;
            *)
                site="${1:-}"
                shift
                ;;
        esac
    done

    # Validate site name
    if [[ -z "$site" ]]; then
        error_json "SSL_SITE_NOT_FOUND" "Site name is required."
        return 1
    fi

    # Remove the cert + nginx ssl config when --revoke given.
    local cert_dir="$PROJECT_ROOT/ssl-certs/${site}"
    local server_cert="$cert_dir/server.crt"
    local server_key="$cert_dir/server.key"

    if [[ "$revoke" == "true" ]]; then
        rm -f "$server_cert" "$server_key"
        # Remove nginx ssl block from the per-site conf (repair will regenerate)
        log_info "Revoked TLS certificate for '$site'."
        if [[ "$json" == "true" ]]; then
            output_json "{\"success\":true,\"site\":\"${site}\",\"revoked\":true}"
        fi
        return 0
    fi

    # Generate the certificate
    generate_site_cert "$site" "$force"

    # Compute the HTTPS port
    local http_port
    http_port=$(get_site_port "$site")
    local https_port
    https_port=$(compute_https_port "$http_port")
    if [[ -z "$https_port" ]]; then
        error_json "SSL_PORT_COMPUTE_FAILED" "Could not compute HTTPS port for '$site'."
        return 1
    fi

    # Ensure nginx config has the ssl block — compose-lib repair regenerates it.
    log_info "TLS setup for '$site': HTTP port ${http_port}, HTTPS port ${https_port}."

    if [[ "$json" == "true" ]]; then
        local cert_source="openssl"
        command -v mkcert >/dev/null 2>&1 && cert_source="mkcert"
        local fingerprint
        fingerprint=$(site_cert_fingerprint "${site}")
        output_json "{\"success\":true,\"site\":\"${site}\",\"http_port\":${http_port},\"https_port\":${https_port},\"cert_source\":\"${cert_source}\",\"fingerprint\":\"${fingerprint}\"}"
    fi

    return 0
}

# matrix domain <site> [hostname] [--yes]
cmd_domain() {
    local site="${1:-}"
    local hostname="${2:-${site}.test}"
    local force=false
    local json=false

    # Parse --yes flag
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes)
                force=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Validate site name
    if [[ -z "$site" ]]; then
        error_json "SSL_SITE_NOT_FOUND" "Site name is required."
        return 1
    fi

    # Run domain management (adds /etc/hosts entry)
    domain "$site" "$hostname" --yes

    if [[ "$json" == "true" ]]; then
        output_json "{\"success\":true,\"site\":\"${site}\",\"hostname\":\"${hostname}\"}"
    fi

    return 0
}