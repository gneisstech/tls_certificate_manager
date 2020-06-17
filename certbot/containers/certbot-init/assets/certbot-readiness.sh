#!/usr/bin/env bash

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------

# Arguments
# ---------------------

function certbot-readiness () {
    echo "TLS publisher is running"

    local -r CERTDIR="/etc/letsencrypt"
    local -r RENEW_FAILED="${CERTDIR}/renew_failed.flag"
    local -r DEVELOPER_CERTIFICATES_REQUIRED="${CERTDIR}/developer_certificates_required.flag"

    if [[ -e "${DEVELOPER_CERTIFICATES_REQUIRED}" ]]; then
        exit 0
    fi

    if [[ -e "${RENEW_FAILED}" ]]; then
        exit 1
    fi
}

certbot-readiness
