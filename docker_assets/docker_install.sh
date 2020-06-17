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

function install_tds () {
  wget http://www.freetds.org/files/stable/freetds-1.1.6.tar.gz
  tar -xzf freetds-1.1.6.tar.gz
  cd freetds-1.1.6
  ./configure --prefix=/usr/local --with-tdsver=7.3 --with-gnutls
  make
  make install
}

function install_tools () {
  apk add --no-cache --update 'build-base' 'gnutls-dev' # 'ruby-nokogiri'
  gem install bundler:2.0.2
  gem install rake -v '12.3.2' --source 'https://rubygems.org/'
  ( install_tds )
}

function docker_install () {
    install_tools
}

docker_install
