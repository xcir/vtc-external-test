FROM ubuntu:jammy

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends -yq haproxy curl ca-certificates

RUN export DEBIAN_FRONTEND=noninteractive && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish75/script.deb.sh | /bin/bash

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install --no-install-recommends -yq varnish

##################
# Extra packages #
##################
#RUN export DEBIAN_FRONTEND=noninteractive && \
#    apt-get install --no-install-recommends -yq imagemagick
