#!/usr/bin/env bash

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------
declare -rx HOST_BINDING
declare -rx RELEASE_NAMESPACE
declare -rx RELEASE_NAME
declare -rx ORGANIZATION

# Arguments
# ---------------------

function certificate_domain () {
    echo "${HOST_BINDING}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1".xip.io" } /^[^0-9]+/ { print $1 }'
}

function certificate_ip () {
    echo "${HOST_BINDING}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1 } /^[^0-9]+/ { print "0.0.0.0" }'
}

function certbot-developer-certificate () {
    #
    # default is a self-signed certificate for development
    #

    local -r CERTIFICATE_DIR="/etc/letsencrypt/dev-cert"
    local -r CERTIFICATE_ORG="${ORGANIZATION}"
    local -r CERTIFICATE_NAME="${RELEASE_NAME}"

    mkdir -p "${CERTIFICATE_DIR}"
    openssl genrsa -out "${CERTIFICATE_NAME}.key" 4096
    openssl req -new -sha256 -key "${CERTIFICATE_NAME}.key" -subj "/C=US/ST=CA/O=${CERTIFICATE_ORG}/CN=$(certificate_domain)" -out "${CERTIFICATE_NAME}.csr"
    echo "subjectAltName=DNS:$(certificate_domain),IP:$(certificate_ip)" > extfile.cnf
    openssl x509 -req -days 365 -in "${CERTIFICATE_NAME}.csr" -signkey "${CERTIFICATE_NAME}.key" -out "${CERTIFICATE_NAME}.crt" -extfile extfile.cnf
    cat "${CERTIFICATE_NAME}.crt" "${CERTIFICATE_NAME}.key" > "${CERTIFICATE_DIR}/${CERTIFICATE_NAME}.pem"
    cp "${CERTIFICATE_NAME}.crt" "${CERTIFICATE_NAME}.key" "${CERTIFICATE_DIR}/"
}

certbot-developer-certificate
