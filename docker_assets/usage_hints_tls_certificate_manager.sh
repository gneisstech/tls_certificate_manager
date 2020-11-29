#!/usr/bin/env bash
# usage: usage_hints_tls_certificate_manager.sh

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

function usage_hints_tls_certificate_manager () {
    printf 'USAGE: docker run {container_id} -- /assets/{entry_point}\n'
    printf '       where {entry_point} is any one of the following:\n'
    printf '          certbot_developer_certificate.sh\n'
    printf '          certbot_init_www.sh\n'
    printf '          certbot_issuer_loop.sh\n'
    printf '          certbot_readiness.sh\n'
    printf '          certbot_tls_publisher.sh\n'
    printf '          certbot_wait_for_loadbalancer.sh\n'
    printf '          docker_install.sh\n'
    printf '          health_check_cloud_git_certbot.sh\n'
    printf '          metrics_report.sh\n'
    printf '          post_renewal_attempt.sh\n'
    printf '          pre_renewal_attempt.sh\n'
    printf '          renewed_certificates.sh\n'
    printf '          run_certbot_dynamic_analysis.sh\n'
    printf '          run_certbot_static_analysis.sh\n'
}

usage_hints_tls_certificate_manager
