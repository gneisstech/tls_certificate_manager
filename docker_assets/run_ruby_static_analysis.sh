#!/usr/bin/env bash
# usage: run_ruby_static_analysis.sh

# Exit script if you try to use an uninitialized variable.
set -o nounset

# Exit script if a statement returns a non-true return value.
set -o errexit

# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Environment Variables
# ---------------------
declare -x RAILS_ENV="${RAILS_ENV:-development}"
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

function trace_db_params () {
  rails runner 'puts ActiveRecord::Base.configurations'
}

function run_ruby_static_analysis () {
     RAILS_ENV="$(container_environment)" rubocop
}

run_ruby_static_analysis
