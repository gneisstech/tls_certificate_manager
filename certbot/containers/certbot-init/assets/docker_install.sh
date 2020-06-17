#!/usr/bin/env bash
# usage: docker_install.sh

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

function install_base_tools () {
    apk --no-cache add \
        bash \
        bind-tools \
        curl \
        jq \
        netcat-openbsd \
        openssl
}

function install_kubectl () {
    local -r kube_latest_version="v1.15.1"
    curl -L \
        https://storage.googleapis.com/kubernetes-release/release/${kube_latest_version}/bin/linux/amd64/kubectl \
        -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl
}

function docker_install () {
    install_base_tools
    install_kubectl
}

docker_install
