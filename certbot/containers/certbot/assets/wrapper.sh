#!/bin/sh -
#
# Maintainer: techguru@byiq.com
#
# Copyright (c) 2017,  Cloud Git -- All Rights Reserved
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

set -e

CERTDIR=/etc/letsencrypt
CERTIFICATES_CREATED=$CERTDIR/certificates_created.flag
RENEWFAILED=$CERTDIR/renew_failed.flag

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

PATH=$SCRIPTPATH:$PATH

CERTIFICATE_DOMAIN=$( echo "${HOST_DOMAIN}" | awk 'BEGIN {FS=":"} /^[0-9]+/ { print $1".xip.io" } /^[^0-9]+/ { print $1 }' )

if [ "${IS_PRODUCTION}" != "production" ]
then
    STAGING="--staging"
else
    STAGING=
fi

sigterm_handler() {
    echo "SIGTERM signal received, try to gracefully shutdown all services..."
}

certbot_new_certificates() {
    echo "creating new certificates at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"

    (
        certbot certonly \
            -n \
            $STAGING \
            --webroot \
            --webroot-path /data/letsencrypt \
            -d "${CERTIFICATE_DOMAIN}" \
            -m "${ADMIN_EMAIL}" \
            --agree-tos \

    ) && touch $CERTIFICATES_CREATED
}

certbot_renew_certificates() {
    echo "checking if certificates need renewal at [$(date)] : container started at [$(stat -c "%z" /proc/1/cmdline)]"
    certbot renew \
        --rsa-key-size 4096 \
        --pre-hook "pre_renewal_attempt.sh" \
        --post-hook "post_renewal_attempt.sh" \
        --renew-hook "renewed_certificates.sh" \

}

is_our_server_available() {
    curl --silient "http://${HOST_DOMAIN}//.well-known/.showme.html" | grep "available"
}

trap "sigterm_handler; exit" TERM

# Wait for SIGTERM
# check for our site to be available on the public internet
echo "waiting for our server to be available on the Internet"
until is_our_server_available
do
    sleep 30
    is_our_server_available || echo "... still waiting for our server ..."
done

# Wait for SIGTERM
# check for creation of new certificate every 130 seconds to avoid rate-limit
while [ ! -e $CERTIFICATES_CREATED ]
do
    echo "new certificates needed"
    certbot_new_certificates || (echo "failed to create new certificate" && sleep 130)
done

# Wait for SIGTERM
# check for certificate renewal daily.
# if renewal fails, check hourly and raise healthcheck alert
while true
do
    certbot_renew_certificates || touch $RENEWFAILED
    if [ -e $RENEWFAILED ]
    then
        sleep 3600
        rm -f $RENEWFAILED
    else
        sleep 86400
    fi
done
