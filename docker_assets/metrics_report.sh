#!/usr/bin/env bash
# usage: metrics_report.sh

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------
declare -rx STATSD_HOST
declare -rx STATSD_PORT

function metrics_report {
    local -r metric_tag="$1"
    local -r metric_value="$2"
    # placeholder
    echo "metric tag [${metric_tag}]=[${metric_value}]" > /dev/stderr
    if [[ -n "${STATSD_HOST}" ]]; then
        echo "${metric_tag}:${metric_value}|g" > "/dev/udp/${STATSD_HOST}/${STATSD_PORT}"
    fi
}

metrics_report "$@"
