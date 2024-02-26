FROM ubuntu:jammy

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish74/script.deb.sh | /bin/bash && \
    apt-get install --no-install-recommends -yq haproxy curl ca-certificates && \
    apt-get install --no-install-recommends -yq varnish
