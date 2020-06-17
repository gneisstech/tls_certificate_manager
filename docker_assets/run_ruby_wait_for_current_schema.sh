#!/usr/bin/env bash
# usage: run_ruby_wait_for_current_schema.sh

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------
declare -rx RAILS_ENV
declare -rx APPSETTING_RAILS_ENV

# Arguments
# ---------------------

function container_environment () {
  local theEnvironment="development"
  if [[ -n "${RAILS_ENV:-}" ]]; then
    theEnvironment="${RAILS_ENV}"
  fi
  if [[ -n "${APPSETTING_RAILS_ENV:-}" ]]; then
    theEnvironment="${APPSETTING_RAILS_ENV}"
  fi
  echo "${theEnvironment}"
}

function rake_has_pending_migrations () {
    ! rake db:abort_if_pending_migrations RAILS_ENV="$(container_environment)"
}

function run_ruby_wait_for_current_schema () {
    local -r begin_time="${SECONDS}"
    while rake_has_pending_migrations; do
        sleep 10
        echo "Waiting on current schema for ${SECONDS}"
    done
    /assets/metrics_report.sh 'cf_schema_delay' "$(( SECONDS - begin_time))"
}

run_ruby_wait_for_current_schema
