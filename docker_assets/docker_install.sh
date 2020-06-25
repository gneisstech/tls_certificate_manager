#!/usr/bin/env bash
# usage: docker_install.sh

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

# Arguments
# ---------------------

function install_base_tools () {
    apk --no-cache add \
        bash \
        bind-tools \
        curl \
        jq \
        netcat-openbsd \
        openssl \
        shellcheck
}

function install_kubectl () {
    local -r kube_latest_version="v1.17.7"
    curl -L \
        https://storage.googleapis.com/kubernetes-release/release/${kube_latest_version}/bin/linux/amd64/kubectl \
        -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl
}

function create_mount_points () {
    mkdir -p /etc/letsencrypt
    mkdir -p /data/letsencrypt
}

function retrieve_certbot () {
    local -r certbot_version="${1}"
    # Retrieve certbot code
    mkdir -p src
    wget -O "certbot-${certbot_version}.tar.gz" "https://github.com/certbot/certbot/archive/v${certbot_version}.tar.gz"
    tar xf "certbot-${certbot_version}.tar.gz"
    find .
    cp "certbot-${certbot_version}/CHANGELOG.md" "certbot-${certbot_version}/README.rst" src/
    cp "certbot-${certbot_version}/letsencrypt-auto-source/pieces/dependency-requirements.txt" .
    cp "certbot-${certbot_version}/letsencrypt-auto-source/pieces/pipstrap.py" .
    cp -r "certbot-${certbot_version}/tools" "tools"
    cp -r "certbot-${certbot_version}/acme" "src/acme"
    cp -r "certbot-${certbot_version}/certbot" "src/certbot"
    rm -rf "certbot-${certbot_version}.tar.gz" "certbot-${certbot_version}"
}

function generate_constraints () {
    # Generate constraints file to pin dependency versions
    cat dependency-requirements.txt | tools/strip_hashes.py > unhashed_requirements.txt
    cat tools/dev_constraints.txt unhashed_requirements.txt | tools/merge_requirements.py > docker_constraints.txt
}

function install_certbot_runtime_dependencies () {
    # Install certbot runtime dependencies
    apk add --no-cache --virtual .certbot-deps \
        libffi \
        libssl1.1 \
        openssl \
        ca-certificates \
        binutils
}

function install_certbot_from_sources () {
    # Install certbot from sources
    apk add --no-cache --virtual .build-deps \
        gcc \
        linux-headers \
        openssl-dev \
        musl-dev \
        libffi-dev
    python pipstrap.py
    pip install --upgrade pip
    pip install -r dependency-requirements.txt
    pip install --no-cache-dir --no-deps \
        --editable src/acme \
        --editable src/certbot
    apk del .build-deps
}

function install_qemu () {
    QEMU_ARCH="x86_64"
    pushd /tmp
        QEMU_DOWNLOAD_URL="https://github.com/multiarch/qemu-user-static/releases/download"
        QEMU_LATEST_TAG="$(curl -s https://api.github.com/repos/multiarch/qemu-user-static/tags \
            | grep 'name.*v[0-9]' \
            | head -n 1 \
            | cut -d '"' -f 4 || true)"
        printf 'foo\n'
        curl -SL "${QEMU_DOWNLOAD_URL}/${QEMU_LATEST_TAG}/x86_64_qemu-$QEMU_ARCH-static.tar.gz" \
            | tar xzv
        cp "qemu-${QEMU_ARCH}-static" /usr/bin
    popd
}

function install_certbot () {
    mkdir -p /opt/certbot && chmod 777 /opt/certbot
    mkdir -p /etc/letsencrypt
    mkdir -p /var/lib/letsencrypt
    install_qemu
    pushd /opt/certbot
        retrieve_certbot '1.5.0'
        generate_constraints
        install_certbot_runtime_dependencies
        install_certbot_from_sources
    popd
}

function docker_install () {
    install_base_tools
    install_kubectl
    create_mount_points
    install_certbot
}

docker_install
