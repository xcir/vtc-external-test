# vtc-external-test

This is a script for easy unit testing using varnishtest for domains in CDNs, etc.


| | |
|--|:--|
| Author:                   | Shohei Tanaka(@xcir) |
| Date:                     | - |
| Version:                  | trunk |
| Manual section:           | 7 |

# Require

- docker
- curl (when using `curl.sh`)

# Quick tutorial

```
xcir@DESKTOP-UL5EP50:~/git/vtc-ext-test$ cat tests/example.vtc 
vtest "example.net"

# ./tests/template/ha.vtc
include /mnt/tests/template/ha.vtc

client c_http -connect ${h1_fe2_sock} {
    txreq -req GET -url "/" -hdr "Host: example.net"
    rxresp
    expect resp.status        == "200"
} -run

client c_http -connect ${h1_fe1_sock} {
    txreq -req GET -url "/" -hdr "Host: example.net"
    rxresp
    expect resp.status        == "200"
} -run

xcir@DESKTOP-UL5EP50:~/git/vtc-ext-test$ cat tests/template/ha.vtc
################################################################
# HAProxy Template
# https = h1_fe1_sock
# http  = h1_fe2_sock
################################################################

feature ignore_unknown_macro
feature cmd {haproxy --version 2>&1 | grep -q 'HA-*Proxy version'}
haproxy h1 -conf {
    defaults
        mode   http
        timeout connect         5s
        timeout server          5s
        timeout client          5s

    backend be1
        #https
        server srv1 ${target}:443 ssl verify none sni req.hdr(Host)
    backend be2
        #http
        server srv1 ${target}:80

    frontend fe1
        #https
        use_backend be1
        bind "fd@${fe1}"
    frontend fe2
        #http
        use_backend be2
        bind "fd@${fe2}"
} -start

xcir@DESKTOP-UL5EP50:~/git/vtc-ext-test$ ./vtc.sh -c example.net tests/example.vtc 
==============================================
  Target Server: example.net
            VTC: /home/xcir/git/vtc-ext-test/tests/example.vtc
==============================================
#    top  TEST /mnt/tests/test.vtc passed (5.951)
```


# What is this?

See [this article.](https://labs.gree.jp/blog/?p=23009)

# vtc.sh


## Options

```
Usage: ./vtc.sh [-h] [-v] [-s] [-f] [-n target name] [-c connection server] [-o extra varnishtest option] [-e extra varnishtest option name] [vtc_file or vtc_dir]
    -s Entering docker container shell
    -f Force rebuild docker image
    -h Show this help
    -v Enable verbose mode
Example: ./vtc.sh -c example.net tests/example.vtc
```


| option | explanation | default | example |
|-|:-|:-|:-|
| -h                                    | help    | - | - |
| -v                                    | Enable verbose mode    | - | - |
| -s                                    | Entering docker container shell    | - | - |
| -f                                    | Force rebuild docker image    | - | - |
| -n [target name]                      | Name of the target server defined in `conf.sh` | `default` | `-n stg` |
| -c [connection server]                | Specify the connection server    | - | `-c example.net` |
| -o [extra varnishtest option]         | Used to specify additional macros, etc. to varnishtest   | - | `-o "-Dmacro=1"` |
| -e [extra varnishtest option name]    | Name of the extra option defined in `conf.sh`  | - | `-e example` |
| [vtc_file or vtc_dir]                 | Specify a single vtc or path | `tests/` | `tests/example.net.vtc` |

# curl.sh

Generate curl commands using `conf.sh`.
It is used for a small check.

## Options
```
Usage: ./curl.sh [--vn target name] [--vc connection server] [--ve extra curl option name] [--vp port] [--verbose] [curl options / URL]
Example: ./curl.sh --verbose --vc example.net -I http://example.net
--verbose can be used to check the generated curl commands
```
| option | explanation | default | example |
|-|:-|:-|:-|
| --verbose                        | Verbose mode  | - | - |
| --vn [target name]               | Name of the target server defined in `conf.sh` | - | `--vn stg` |
| --vc [connection server]         | Specify the connection server    | - | `--vc example.net` |
| --ve [extra curl option name]    | Name of the extra option defined in `conf.sh` | - | `--ve akamai` |
| --vp [port]                      | Use want to change the port to connect to (`--vn`,`--vc` option must be specified) | - | `--vp 8080` |
| [curl options / URL ]            | Specify curl options, URL | - | `-I https://example.net` |

# conf.sh

Settings to be used in `vtc.sh`,`curl.sh`

```
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

```

# How to write VTC


```
vtest "test case description"

##############################
# include HAproxy template
include /mnt/tests/template/ha.vtc
##############################

client c_http -connect ${h1_fe2_sock} {
    txreq -req GET -url "/" -hdr "Host: example.net"
    rxresp
    expect resp.http.cache-control   == "max-age=604800"
    expect resp.status               == "200"
} -run

client c_https -connect ${h1_fe1_sock} {
    txreq -req GET -url "/" -hdr "Host: example.net"
    rxresp
    expect resp.http.cache-control   == "max-age=604800"
    expect resp.status               == "200"
} -run

```

VTC needs to `include /mnt/tests/template/ha.vtc` to test the external domain.
Please copy&paste.

Specify with `-connect` to connect from the client to the target.


| | |
|--|:--|
| HTTP:                | `client XXX -connect ${h1_fe2_sock} {[testcode]}` |
| HTTPS:               | `client XXX -connect ${h1_fe1_sock} {[testcode]}` |

For other notations, [see.](https://varnish-cache.org/docs/trunk/reference/vtc.html)

## Tips

For example, if you are dynamically generating thumbnails and want to test the format and size, do this.

```
client c_rsz1 -connect ${h1_fe1_sock} {
    txreq -req GET -url "/thumbs/test_640x640.png" -hdr "Host: example.net"
    rxresp
    expect resp.status                  == "200"
    expect resp.http.content-type       == "image/png"
    write_body testimg
    shell -match "PNG 640x640 " { identify testimg }
} -run
```

`write_body testimg` writes a body named testimg and `shell -match "PNG 640x640 " { identify testimg }` expect the result of running the identify command.
The ability to write the body once in a file and check it with various commands like this expands the scope of testing.

Don't forget to install the command in the Dockerfile. :)

# Known issues

## Assert error in vtc_log_emit(), vtc_log.c line 176:

Need more buffer.
increse `VTC_BUFFER_SIZE` in `conf.sh`

## Assert error in http_splitheader(), vtc_http.c line 462:  Condition(n < MAX_HDR) not true.  Errno=0 Success

The maximum number of header lines([MAX_HDR](https://github.com/varnishcache/varnish-cache/blob/varnish-7.4.2/bin/varnishtest/vtc_http.h#L31)) in varnishtest is 64.
For example, if you specify the full Pragma for debugging Akamai, it may be exceeded, so you may want to specify what you need.

## Not working "include"

Use the `-f` option to recreate the image.

# To-Do

