#!/bin/bash

# Generate self-signed certificates for development
# This creates certificates that work for *.127.0.0.1.nip.io domains

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CERT_DIR="$PROJECT_ROOT/ssl-certs"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

function info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

function success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

function warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Create certificate directory
mkdir -p "$CERT_DIR"

info "Generating self-signed SSL certificates for development..."

# Create a config file for the certificate
cat > "$CERT_DIR/cert.conf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=Development
L=Local
O=WordPress Dev
OU=Development
CN=*.127.0.0.1.nip.io

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.127.0.0.1.nip.io
DNS.2 = 127.0.0.1.nip.io
DNS.3 = localhost
DNS.4 = *.localhost
DNS.5 = phpmyadmin.127.0.0.1.nip.io
DNS.6 = mailhog.127.0.0.1.nip.io
DNS.7 = xandar.127.0.0.1.nip.io
DNS.8 = sakaar.127.0.0.1.nip.io
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate private key
info "Generating private key..."
openssl genrsa -out "$CERT_DIR/dev-key.pem" 2048

# Generate certificate
info "Generating certificate..."
openssl req -new -x509 -key "$CERT_DIR/dev-key.pem" -out "$CERT_DIR/dev-cert.pem" -days 365 -config "$CERT_DIR/cert.conf" -extensions v3_req

# Set proper permissions
chmod 600 "$CERT_DIR/dev-key.pem"
chmod 644 "$CERT_DIR/dev-cert.pem"

success "SSL certificates generated successfully!"
echo ""
echo "Certificate files created:"
echo "• Certificate: $CERT_DIR/dev-cert.pem"
echo "• Private Key: $CERT_DIR/dev-key.pem"
echo ""
warning "These are self-signed certificates for development only."
echo "Your browser will show a security warning - this is normal for development."
echo "You can safely proceed by clicking 'Advanced' -> 'Proceed to site'."
echo ""
info "To trust the certificate in your browser:"
echo "1. Open the certificate file: $CERT_DIR/dev-cert.pem"
echo "2. Add it to your system's trusted certificates"
echo "3. Or use browser settings to trust the certificate"