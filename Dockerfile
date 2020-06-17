FROM golang:1.13.7 AS build
WORKDIR /go/src

ENV CGO_ENABLED=0

RUN go get -v -d \
    "github.com/coreos/go-oidc" \
    "github.com/DataDog/datadog-go/statsd" \
	"github.com/sirupsen/logrus"

COPY cmd/cf_tls_certificate_manager/main.go .
COPY src/ .
RUN go build -a -installsuffix cgo -o cf_tls_certificate_manager main.go

FROM scratch AS runtime
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /go/src/cf_tls_certificate_manager ./

ENV JWT_AUTH_TOKEN=''
ENV CF_DISTECH_LIGHTSMAP_API_KEY='xyzzy'
ENV CF_SELF_HEALING_API_KEY='xyzzy'
ENV TEST_HOST_URL='https://cf.dev.atrius-iot.com'
ENV SERVICE_PRINCIPAL_CLIENT_ID=''
ENV SERVICE_PRINCIPAL_TENANT_ID=''
ENV SERVICE_PRINCIPAL_RESOURCE=''
ENV SERVICE_PRINCIPAL_SECRET=''

EXPOSE 3000/tcp
ENTRYPOINT ["./cf_tls_certificate_manager"]
