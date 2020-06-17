#!/usr/bin/env bash

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------
declare -rx HOST_FQDN
declare -rx RELEASE_NAMESPACE
declare -rx RELEASE_NAME
declare -rx PRIVATE_TLS

# Arguments
# ---------------------

function get_ingress_service () {
    kubectl --namespace "${RELEASE_NAMESPACE}" \
        get service \
        -l "component=controller,certbot=${HOST_FQDN}" \
        -o json \
        2>/dev/null
}

function filter_ingress_service_hostname () {
    jq -r -e '.items[0].status.loadBalancer.ingress | .[0].hostname' 2>/dev/null || false
}

function filter_ingress_service_ip () {
    jq -r -e '.items[0].status.loadBalancer.ingress | .[].ip' 2>/dev/null || false
}

function ingress_fqdn () {
    get_ingress_service | filter_ingress_service_hostname
}

function get_loadbalancer_ip () {
    get_ingress_service | filter_ingress_service_ip
}

function domain_dns_dig () {
    local -r fqdn="${1}"
    dig "${fqdn}" @8.8.8.8 +nocomments +noquestion +noauthority +noadditional +nostats
}

function extract_ip_from_dns_dig () {
    awk '$4 ~ /^A$/ {print $5}'
}

function domain_dns_ip_list () {
    local -r fqdn="${1}"
    echo "Examining domain: [${fqdn}]" > /dev/stderr
    domain_dns_dig "${fqdn}" | extract_ip_from_dns_dig | sort -u | tee /dev/stderr
    echo "Examined domain: [${fqdn}]" > /dev/stderr
}

function intersect_host_fqdn_with_ingress_fqdn () {
    comm -12 <(domain_dns_ip_list "${HOST_FQDN}") <(domain_dns_ip_list "$(ingress_fqdn)")
}

function fail_empty_set () {
    grep -q '^'
}

function verify_ingress_domain () {
    # returns false if the intersection of the two ip lists is empty set
    intersect_host_fqdn_with_ingress_fqdn | tee /dev/stderr | fail_empty_set
}

function verify_ip () {
    grep -e '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
}

function verify_loadbalancer () {
    verify_ingress_domain && return 0
    get_loadbalancer_ip | verify_ip && return 0
    return 1
}

function wait_for_loadbalancer {
    until verify_loadbalancer; do
        echo 'waiting for loadbalancer to have static ip assignment'
        sleep 15
    done
    echo 'loadbalancer is ready!'
}

function is_private_tls () {
    if [[ "${PRIVATE_TLS:-false}" != "true" ]]
    then
        return 1
    fi;
    echo 'private TLS key is already published as a cluster secret'
}

is_private_tls || wait_for_loadbalancer
