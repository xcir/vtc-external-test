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