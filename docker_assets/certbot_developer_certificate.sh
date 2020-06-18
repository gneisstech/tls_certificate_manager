#!/usr/bin/env bash
# usage: certbot_developer_certificate.sh

#
# Maintainer: techguru@byiq.com
#
# Copyright (c) 2017-2020,  Cloud Git -- All Rights Reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------
declare -rx HOST_DOMAIN
declare -rx DEV_CERTIFICATE_DIR
declare -rx CERTIFICATE_ORG
declare -rx CERTIFICATE_NAME

# Arguments
# ---------------------

function certificate_domain () {
    echo "${HOST_DOMAIN}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1".xip.io" } /^[^0-9]+/ { print $1 }'
}

function certificate_ip () {
    echo "${HOST_DOMAIN}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1 } /^[^0-9]+/ { print "0.0.0.0" }'
}

function certbot_developer_certificate () {
    local -r csrFile="${CERTIFICATE_NAME}.csr"
    local -r crtFile="${CERTIFICATE_NAME}.crt"
    local -r keyFile="${CERTIFICATE_NAME}.key"
    local -r pemFile="${CERTIFICATE_NAME}.pem"
    SECONDS=0
    #
    # create default certificate as a self-signed certificate for development
    #

    mkdir -p "${DEV_CERTIFICATE_DIR}"
    pushd "${DEV_CERTIFICATE_DIR}"
        openssl genrsa -out "${keyFile}" 4096
        openssl req -new -sha256 -key "${keyFile}" -subj "/C=US/ST=CA/O=${CERTIFICATE_ORG}/CN=$(certificate_domain)" -out "${csrFile}"
        openssl x509 -req -days 365 -in "${csrFile}" -signkey "${keyFile}" -out "${crtFile}" -extfile <(printf 'subjectAltName=DNS:%s,IP:%s' "$(certificate_domain)" "$(certificate_ip)")
        cat "${crtFile}" "${keyFile}" > "${pemFile}"
    popd
    /assets/metrics_report.sh "${FUNCNAME[0]}" "${SECONDS}"
}

certbot_developer_certificate
