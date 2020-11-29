# tls certificate manager for kubernetes ingress

automatically updates the specific TLS secret used by k8s ingress
using EFF Certbot and ACME protocol with registrar "LetsEncrypt"

keep it simple.  keep it boring.  keep it DRY

1. boring tooling to update TLS Certificates used by Kubernetes (K8S) ingress
   1. if no certificate exists and no certificate provided, creates a self-signed certificate
      1. after creating self-signed certificate, attempts to create new certificate using Let's Encrypt provider
   1. if certificate provided, uses that and only that
   1. if certificate exists, and is a Let's Encrypt compatible, then watch and renew when needed
1. boring tooling to maintain HELM charts and auto update its semver and deployment packaging based on
   1. semver changes of included services or charts;
1. boring tooling for container management
   1. maintain semver
   1. add metadata for audit and tracability
      1. source repository
      1. commit SHA
      1. semver tagging
      1. available configuration environment variables
      1. openapi spec
   1. standardized entry points for test and deployment operations
      1. unit test
      1. static analysis
      1. dynamic analysis
      1. data model migration

Always room for improvement, submissions are invited
Issue Tracker: https://gitlab.com/acuitytech/tls_certificate_manager/-/issues

```

# Copyright (c) 2016-2017, techguru@byiq.com
# Copyright (c) 2017-2019, Cloud Scaling
# Copyright (c) 2019-2020, Acuity Brands Lighting Inc.
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
```
