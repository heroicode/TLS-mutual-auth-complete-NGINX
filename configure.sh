#!/usr/bin/env sh
# shellcheck disable=SC2039  # local keyword is fine, actually
set -o errexit -o nounset -o noclobber
dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd); cd "$dir/conf"

openssl() {
    local pem="$1"
    [ -e "$pem" ] && return
    shift
    echo "Generating $pem"
    # /usr/local/opt/openssl@3/bin/openssl
    "$(command -v "${OPENSSL:-/opt/homebrew/bin/openssl}" \
         || command -v openssl)" \
        "$@" 2>/dev/null
}

# set -x

openssl root.pem req -nodes -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 \
    -days 3650 \
    -text -keyout root.pem -out root.pem \
    -subj "/C=US/ST=ZZ/L=Any/O=Dev/OU=Local/CN=localhost CA" \
    -addext keyUsage=critical,nonRepudiation,cRLSign,keyCertSign \

openssl https.pem req -nodes -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 \
    -days 3650 \
    -text -keyout https.pem -out https.pem \
    -CA root.pem -key root.pem \
    -subj "/C=US/ST=ZZ/L=Any/O=Dev/OU=Local/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1" \
    -addext basicConstraints=critical,CA:FALSE \

# -new seems to be implied but we use it anyway
openssl client.pem req -nodes -x509 -days 750 -sha256 -new \
    -text -keyout client.pem -out client.pem \
    -CA root.pem -key root.pem \
    -subj "/C=US/ST=ZZ/L=Any/O=Dev/OU=Local/CN=http client" \
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1" \
    -addext basicConstraints=critical,CA:FALSE \
    -addext subjectKeyIdentifier=hash \
    -addext authorityKeyIdentifier=keyid,issuer \
    -addext nsCertType=client,email \
    -addext keyUsage=critical,nonRepudiation,digitalSignature,keyEncipherment \
    -addext extendedKeyUsage=clientAuth,emailProtection \
    -addext nsComment="Local Test Client Certificate" \

openssl bad-client.pem req -nodes -x509 -days 750 -sha256 -new \
    `#-CA root.pem -key root.pem` \
    -text -keyout bad-client.pem -out bad-client.pem \
    -subj "/C=US/ST=ZZ/L=Any/O=Dev/OU=Local/CN=http client" \
    -addext basicConstraints=critical,CA:FALSE \
    -addext subjectKeyIdentifier=hash \
    -addext authorityKeyIdentifier=keyid,issuer \
    -addext nsCertType=client,email \
    -addext keyUsage=critical,nonRepudiation,digitalSignature,keyEncipherment \
    -addext extendedKeyUsage=clientAuth,emailProtection \
    -addext nsComment="Local Test Client Certificate" \




