FROM amd64/python:3.8-alpine3.12
LABEL maintainer="techguru@byiq.com"
LABEL cloud-git-role="cloud-git-nginx-certbot"

ADD ./docker_assets/* /assets/
WORKDIR /assets
RUN apk add --no-cache bash curl && ./docker_install.sh

ENV ACTIVE_TLS_PUBLISH='false'
ENV ADMIN_EMAIL='techguru@byiq.com'
ENV HOST_DOMAIN='br.dev.atrius-iot.com'
ENV RELEASE_NAMESPACE='brk8s'
ENV RELEASE_NAME='br-dev'
ENV INGRESS_APP='br-waf-ingress'
ENV PRIVATE_TLS='false'
ENV TLS_PEM=''
ENV STATSD_HOST='localhost'
ENV STATSD_PORT='8125'
ENV METRICS_PREFIX="br.service.br_tls_certificate_manager."
ENV IS_PRODUCTION='false'
ENV TLS_SECRET_NAME='waf-tls-secret'

ENV CERTIFICATE_ORG='Acuity Brands, Inc.'
ENV CERTIFICATE_NAME="${RELEASE_NAME}"
ENV CERTIFICATE_DIR='/etc/letsencrypt'
ENV DEV_CERTIFICATE_DIR="${CERTIFICATE_DIR}/dev-cert"
ENV WEBROOT_DIR='/data/letsencrypt'

ENV CERTIFICATE_CREATED_FLAG="${CERTIFICATE_DIR}/certificate_created.flag"
ENV RENEWAL_FAILED_FLAG="${CERTIFICATE_DIR}/renewal_failed.flag"
ENV DEVELOPER_CERTIFICATE_REQUIRED_FLAG="${CERTIFICATE_DIR}/developer_certificate_required.flag"

#
# this container will have many different entry point scripts available
# the default script will simply output instructions for use
#
EXPOSE 80 443
VOLUME /etc/letsencrypt /var/lib/letsencrypt
ENTRYPOINT [ "/bin/bash" ]
CMD [ "/assets/usage_hints_tls_certificate_manager.sh" ]
