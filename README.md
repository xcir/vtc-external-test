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
            VTC: /home/xcir/work/akamai/vtc-external-test/tests/example.vtc
==============================================
#    top  TEST /mnt/tests/test.vtc passed (5.951)
```

# What is this?

See [this article.](https://labs.gree.jp/blog/?p=23009)

# Options

```
Usage: ./vtc.sh [-h] [-v] [-s] [-f] [-n target name] [-c connection server] [-o extra varnishtest option] [vtc_file or vtc_dir]
    -s Entering docker container shell
    -f Force rebuild docker image
    -h Show this help
    -v Enable verbose mode
Example: ./vtc.sh -c example.net tests/example.vtc
```


| option | explanation | default | example |
|-|:-|:-|:-|
| -h       | help    | - | - |
| -v        | Enable verbose mode    | - | - |
| -s        | Entering docker container shell    | - | - |
| -f        | Force rebuild docker image    | - | - |
| -n [target name]       | Name of the target server defined in `conf.sh` | `default` | `-n stg` |
| -c [connection server]    | Specify the connection server    | - | `-c example.net` |
| -o [extra varnishtest option]         | Used to specify additional macros, etc. to varnishtest   | - | `-o "-Dmacro=1"` |
| [vtc_file or vtc_dir] | Specify a single vtc or path | `tests/` | `tests/example.net.vtc` |

# conf.sh

```
#!/bin/sh

# Define the target server to be used with the -n option.
# Example: if you want to target example.net when specifying `-n staging``, define C_staging="example.net".
# default is `C_default`.

#C_stg="staging.example.net"
#C_prod="example.net"
#C_default="${C_stg}"

# Specify the path of the VTC.
# This is the default value if VTC is not specified at execution.
DEFAULT_VTC_DIR="${SCRIPT_DIR}/tests"

# varnishd -j value(parallel)
VTC_JOBS=3

# varnishtest -b option(buffer size, default 1M)
VTC_BUFFER_SIZE=3M

# docker image name
DOCKER_IMAGE_NAME="vtc-external-test"
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

