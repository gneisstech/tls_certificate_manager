#!/usr/bin/env bash
# usage: certbot_tls_publisher.sh

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
declare -rx RELEASE_NAMESPACE
declare -rx PRIVATE_TLS
declare -rx TLS_SECRET_NAME
declare -rx DEV_CERTIFICATE_DIR
declare -rx CERTIFICATE_NAME
declare -rx CERTIFICATE_CREATED_FLAG
declare -rx RENEWAL_FAILED_FLAG
declare -rx DEVELOPER_CERTIFICATE_REQUIRED_FLAG
declare -rx ACTIVE_TLS_PUBLISH

# Arguments
# ---------------------

# Globals
# ---------------------

function certificate_domain () {
    echo "${HOST_DOMAIN}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1".xip.io" } /^[^0-9]+/ { print $1 }'
}

function get_ingresses () {
    kubectl get ingress --namespace "${RELEASE_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'
}

function patch_ingress () {
    if [[ $# != 3 ]]; then return 1; fi

    local -r namespace="${1}"
    local -r ingress_name="${2}"
    local -r random_key="${3}"

    local patch_string
    patch_string="$( printf '{"metadata":{"labels":{"dummy":"%s"}}}' "${random_key}" )"

    kubectl patch ingress --namespace "${namespace}" "${ingress_name}" -p "${patch_string}" || true
}

# ingress pod auto reloads configuration when ingress labels change
# some older ingress pods DO NOT reload configuration when the secret changes
# see: https://github.com/kubernetes/ingress-nginx/issues/947#issuecomment-314492913
function restart_ingress_resources () {
    echo "restarting ingresses with new TLS certificate"
    local random_key namespace
    random_key="$(hexdump -n 27 -e '"%02X"'  /dev/urandom)"
    namespace="${RELEASE_NAMESPACE}"

    for ingress in $(get_ingresses); do
        patch_ingress "$namespace" "$ingress" "$random_key";
    done
}

function publish_tls_secret () {
    local -r tlsKeyFile="${1}"
    local -r tlsCertFile="${2}"
    if [[ "${ACTIVE_TLS_PUBLISH}" == "true" ]]; then
        kubectl --namespace "${RELEASE_NAMESPACE}" delete secret "${TLS_SECRET_NAME}" || true
        kubectl --namespace "${RELEASE_NAMESPACE}" create secret tls "${TLS_SECRET_NAME}" --key "${tlsKeyFile}" --cert "${tlsCertFile}"
        restart_ingress_resources
    else
        printf 'Bypassing active tls publishing due to environment flag "ACTIVE_TLS_PUBLISH" \n'
        sleep 120
    fi
}

function publish_dev_tls () {
    echo "publishing self-signed developer certificates"
    local -r tlsKeyFile="${DEV_CERTIFICATE_DIR}/${CERTIFICATE_NAME}.key"
    local -r tlsCertFile="${DEV_CERTIFICATE_DIR}/${CERTIFICATE_NAME}.crt"
    publish_tls_secret "${tlsKeyFile}" "${tlsCertFile}"
}

function publish_certbot_tls_with_renew () {
    local -r tlsKeyFile="privkey.pem"
    local -r tlsCertFile="fullchain.pem"

    local dnsCertificateDir
    dnsCertificateDir="/etc/letsencrypt/$(certificate_domain)"
    local leCertificateDir
    leCertificateDir="/etc/letsencrypt/live/$(certificate_domain)"

    mkdir -p "${dnsCertificateDir}"

    if [[ -e "${dnsCertificateDir}/${tlsCertFile}" ]]; then
        publish_tls_secret "${dnsCertificateDir}/${tlsKeyFile}" "${dnsCertificateDir}/${tlsCertFile}"
    fi

    while true
    do
        if ! cmp -s "${leCertificateDir}/${tlsCertFile}" "${dnsCertificateDir}/${tlsCertFile}"
        then
            echo "copying fresh certificates ... at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
            cp "${leCertificateDir}/${tlsCertFile}" "${dnsCertificateDir}/${tlsCertFile}"
            cp "${leCertificateDir}/${tlsKeyFile}" "${dnsCertificateDir}/${tlsKeyFile}"

            publish_tls_secret "${dnsCertificateDir}/${tlsKeyFile}" "${dnsCertificateDir}/${tlsCertFile}"
        fi
        sleep 30
    done
}

function publish_public_tls () {
    if [[ ! -e "${CERTIFICATE_CREATED_FLAG}" ]]
    then
        publish_dev_tls;
    fi

    until [[ -e "${CERTIFICATE_CREATED_FLAG}" ]]
    do
        sleep 30
        echo "checking for certificates ... at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
    done

    publish_certbot_tls_with_renew # does not return unless container terminated
}

function certbot_tls_publisher () {
    if [[ "${PRIVATE_TLS:-false}" == "true" ]]; then
        echo "private TLS key is already published as a cluster secret"
    elif ( certificate_domain | grep "xip.io" ); then
        touch "${DEVELOPER_CERTIFICATES_REQUIRED}"
        publish_dev_tls;
    else
        publish_public_tls;
    fi

    tail -f /dev/null   # pause so that we can inspect container contents
}

set -x
certbot_tls_publisher   # does not return
