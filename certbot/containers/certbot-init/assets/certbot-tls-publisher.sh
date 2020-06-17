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
declare -rx PRIVATE_TLS

# Arguments
# ---------------------

# Globals
# ---------------------
declare -rx CERTDIR=/etc/letsencrypt
declare -rx CERTIFICATES_CREATED=${CERTDIR}/certificates_created.flag
declare -rx RENEW_FAILED=${CERTDIR}/renew_failed.flag

function certificate_domain () {
    echo "${HOST_BINDING}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1".xip.io" } /^[^0-9]+/ { print $1 }'
}

function get_ingresses () {
    kubectl get ingress --namespace "${RELEASE_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'
}

function patch_ingress () {
    if [[ $# != 3 ]]; then return 1; fi

    local namespace="$1"
    local ingress_name="$2"
    local random_key="$3"

    local patch_string
    patch_string="$( printf '{"metadata":{"labels":{"dummy":"%s"}}}' "${random_key}" )"

    kubectl patch ingress --namespace "$namespace" "$ingress_name" -p "$patch_string" || true
}

# ingress pod auto reloads configuration when ingress rules change
# some older ingress pods DO NOT reload configuration when the secret changes
# see: https://github.com/kubernetes/ingress-nginx/issues/947#issuecomment-314492913
function restart_ingress_resources () {
    echo "restarting ingresses with new TLS certificate"
    local random_key
    random_key="$(hexdump -n 27 -e '"%02X"'  /dev/urandom)"
    namespace="${RELEASE_NAMESPACE}"

    for ingress in $(get_ingresses); do
        patch_ingress "$namespace" "$ingress" "$random_key";
    done
}

function publish_tls_secret () {
    TLS_KEY=$1
    TLS_CERT=$2
    kubectl --namespace "${RELEASE_NAMESPACE}" delete secret "ingress-tls-secret" || true
    kubectl --namespace "${RELEASE_NAMESPACE}" create secret tls "ingress-tls-secret" --key "${TLS_KEY}" --cert "${TLS_CERT}"
    restart_ingress_resources
}

function publish_dev_tls () {
    echo "publishing self-signed developer certificates"
    DEV_CERTIFICATE_DIR="/etc/letsencrypt/dev-cert"
    CERTIFICATE_NAME="${RELEASE_NAME}"
    TLS_KEY_FILE="${DEV_CERTIFICATE_DIR}/${CERTIFICATE_NAME}.key"
    TLS_CRT_FILE="${DEV_CERTIFICATE_DIR}/${CERTIFICATE_NAME}.crt"
    publish_tls_secret "${TLS_KEY_FILE}" "${TLS_CRT_FILE}"
}

function publish_certbot_tls_with_renew () {
    TLS_KEY_FILE=privkey.pem
    TLS_CRT_FILE=fullchain.pem

    DNS_CERTIFICATE_DIR="/etc/letsencrypt/$(certificate_domain)"
    LE_CERTIFICATE_DIR="/etc/letsencrypt/live/$(certificate_domain)"

    mkdir -p "${DNS_CERTIFICATE_DIR}"

    if [[ -e "${DNS_CERTIFICATE_DIR}/${TLS_CRT_FILE}" ]]; then
        publish_tls_secret "${DNS_CERTIFICATE_DIR}/${TLS_KEY_FILE}" "${DNS_CERTIFICATE_DIR}/${TLS_CRT_FILE}"
    fi

    while true
    do
        if ! cmp -s "${LE_CERTIFICATE_DIR}/${TLS_CRT_FILE}" "${DNS_CERTIFICATE_DIR}/${TLS_CRT_FILE}"
        then
            echo "copying fresh certificates ... at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
            cp "${LE_CERTIFICATE_DIR}/${TLS_CRT_FILE}" "${DNS_CERTIFICATE_DIR}/${TLS_CRT_FILE}"
            cp "${LE_CERTIFICATE_DIR}/${TLS_KEY_FILE}" "${DNS_CERTIFICATE_DIR}/${TLS_KEY_FILE}"

            publish_tls_secret "${DNS_CERTIFICATE_DIR}/${TLS_KEY_FILE}" "${DNS_CERTIFICATE_DIR}/${TLS_CRT_FILE}"
        fi
        sleep 30
    done
}

function publish_public_tls () {
    if [[ ! -e "${CERTIFICATES_CREATED}" ]]
    then
        publish_dev_tls;
    fi

    until [[ -e "${CERTIFICATES_CREATED}" ]]
    do
        sleep 30
        echo "checking for certificates ... at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
    done

    publish_certbot_tls_with_renew # does not return unless container terminated
}

function certbot-tls-publisher () {
    #
    # default: use self-signed default certificate if:
    # 1) we are on a private domain, or
    # 2) the LetsEncrypt Certificate is not yet issued/ready
    #
    if ( certificate_domain| grep "xip.io" )
    then
        DEVELOPER_CERTIFICATES_REQUIRED="${CERTDIR}/developer_certificates_required.flag"
        touch "${DEVELOPER_CERTIFICATES_REQUIRED}"
        publish_dev_tls;
    elif [[ "${PRIVATE_TLS:-false}" == "true" ]]
    then
        echo "private TLS key is already published as a cluster secret"
    else
        publish_public_tls;
    fi

    tail -f /dev/null
}

certbot-tls-publisher
