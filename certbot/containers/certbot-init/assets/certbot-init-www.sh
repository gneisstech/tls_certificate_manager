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

function certbot-init-www () {
    chmod 755 "/usr/share/nginx/html";
    touch "/usr/share/nginx/html/index.html";
    chmod 644 "/usr/share/nginx/html/index.html";
    mkdir -p "/usr/share/nginx/html/.well-known/acme-challenge/"
    echo "available" > "/usr/share/nginx/html/.well-known/.showme.html"
    mkdir -p "/usr/share/nginx/html/.test/"
    echo "available" > "/usr/share/nginx/html/.test/.showme.html"
}

certbot-init-www
