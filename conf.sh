#!/bin/sh

# Define the target server to be used with the -n option.
# Example: if you want to target example.net when specifying `-n staging``, define C_staging="example.net".
# default is `C_default`.
C_example="example.net"
C_default="${C_example}"

# Specify the path of the VTC.
# This is the default value if VTC is not specified at execution.
DEFAULT_VTC_DIR="${SCRIPT_DIR}/tests"

# varnishd -j value(parallel)
VTC_JOBS=3

# varnishtest -b option(buffer size, default 1M)
VTC_BUFFER_SIZE=3M

# docker image name
DOCKER_IMAGE_NAME="vtc-external-test"

# vtc.sh --ve option
VTCOPT_example='-Dmacro=1'

# curl.sh --ve option(Array)
# Example: if you want to add a header to the request, define CURLOPT_example=("-H" "X-Example1: example1" "-H" "X-Example2: example2").
# https://community.akamai.com/customers/s/article/Akamairxdxn3?language=en_US
CURLOPT_akamai=("-H" "pragma: akamai-x-cache-on,akamai-x-cache-remote-on,akamai-x-check-cacheable,akamai-x-get-cache-key,akamai-x-get-extracted-values,akamai-x-get-request-id,akamai-x-serial-no, akamai-x-get-true-cache-key")
# https://docs.edgecast.com/cdn/Content/Knowledge_Base/X_EC_Debug.htm
CURLOPT_edgecast=("-H" "X-EC-Debug: x-ec-cache,x-ec-check-cacheable,x-ec-cache-key,x-ec-cache-state")
# https://docs.fastly.com/ja/guides/checking-cache
CURLOPT_fastly=("-H" "Fastly-Debug:1")
