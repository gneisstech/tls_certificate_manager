#!/usr/bin/env bash
# usage: run_certbot_static_analysis.sh

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

function sast_shellcheck () {
    find '/assets' -name '*.sh' -print0 | xargs -0 -n 1 shellcheck
}

function run_certbot_static_analysis () {
    sast_shellcheck
}

run_certbot_static_analysis
