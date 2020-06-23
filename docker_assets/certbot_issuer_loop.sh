#!/usr/bin/env bash
# usage: certbot_issuer_loop.sh.sh

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
declare -rx CERTIFICATE_CREATED_FLAG
declare -rx RENEWAL_FAILED_FLAG
declare -rx HOST_DOMAIN
declare -rx ADMIN_EMAIL
declare -rx IS_PRODUCTION
declare -rx WEBROOT_DIR

# Arguments
# ---------------------

function certificate_domain () {
    echo -n "${HOST_DOMAIN}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1".xip.io" } /^[^0-9]+/ { print $1 }'
}

function staging_flag () {
    if [[ "${IS_PRODUCTION}" != "production" ]]; then
        printf -- '--staging'
    fi
}

function sigterm_handler () {
    printf 'SIGTERM signal received, try to gracefully shutdown all services...\n'
}

function certbot_new_certificates () {
    local -r certbot_cmd="certbot \
            certonly \
            -n \
            $(staging_flag) \
            --webroot \
            --webroot-path ${WEBROOT_DIR} \
            -d $(certificate_domain) \
            -m ${ADMIN_EMAIL} \
            --agree-tos"
    echo "creating new certificates at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
    echo "${certbot_cmd}"
    $certbot_cmd && touch "${CERTIFICATE_CREATED_FLAG}"
}

function certbot_renew_certificates () {
    echo "checking if certificates need renewal at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
    certbot renew \
        --rsa-key-size 4096 \
        --pre-hook "/assets/pre_renewal_attempt.sh" \
        --post-hook "/assets/post_renewal_attempt.sh" \
        --renew-hook "/assets/renewed_certificates.sh"
}

function is_our_server_available () {
    curl --silent "http://${HOST_DOMAIN}/.well-known/.showme.html" | grep "available"
}

function wait_for_server_availability () {
    # Wait for SIGTERM
    # check for our site to be available on the public internet
    printf 'waiting for our server to be available on the Internet\n'
    until is_our_server_available; do
        sleep 30
        if ! is_our_server_available; then
            printf '... still waiting for our server @[%s] seconds...\n' "${SECONDS}"
        fi
    done
}

function wait_for_certificate_creation () {
    # Wait for SIGTERM
    # check for creation of new certificate every 130 seconds to avoid rate-limit
    # and avoid race condition with certificate issuer
    until [[ -e "${CERTIFICATE_CREATED_FLAG}" ]]; do
        printf  'new certificates needed\n'
        if ! certbot_new_certificates; then
            printf 'failed to create new certificate\n'
            sleep "$(( 2 * 60 + 10 ))"  # 2 minutes, 10 seconds
        fi
    done
}

function wait_for_certificate_renewal () {
    # Wait for SIGTERM
    # check for certificate renewal daily.
    # if renewal fails, check hourly and raise healthcheck alert
    while true; do
        if certbot_renew_certificates; then
            rm -f "${RENEWAL_FAILED_FLAG}"
            sleep "$(( 24 * 60 * 60 ))"     # 1 day
        else
            touch "${RENEWAL_FAILED_FLAG}"
            sleep "$(( 60 * 60 ))"          # 1 hour, to avoid rate limit for too many renewal requests
        fi
    done
}

function certbot_issuer_loop () {
    trap "sigterm_handler; exit" TERM
    ls -la /assets > /dev/stderr
    whoami > /dev/stderr
    wait_for_server_availability
    wait_for_certificate_creation   # exit for SIGTERM or certificate creation
    wait_for_certificate_renewal    # does not exit until SIGTERM
}

certbot_issuer_loop