#!/bin/bash

usage_exit() {
  cat << EOF 1>&2
Usage: $0 [--vn target name] [--vc connection server] [--ve extra curl option name] [--vp port] [--verbose] [curl options / URL]
Example: $0 --verbose --vc example.net -I http://example.net
--verbose can be used to check the generated curl commands
EOF
  exit 1
}

### main
shopt -s nocasematch
SCRIPT_DIR=$(cd $(dirname $0); pwd)

CONNECT=""
PARAM=("${@}")
VERBOSE=0
PORT=""

if [[ !("${PARAM[*]}" =~ (https?://[^ ]+)) ]]; then
    echo "URL not found."
    usage_exit
else
    URL="${BASH_REMATCH[1]}"
fi

source ${SCRIPT_DIR}/conf.sh

i=0
for v in "${PARAM[@]}"; do
    case "$v" in
        --vn)
            optarg="${PARAM[$i+1]}"
            if [[ -n "$(eval echo \${C_${optarg}})" ]]; then
                CONNECT="$(eval echo \${C_${optarg}})"
            fi
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --vc)
            optarg="${PARAM[$i+1]}"
            CONNECT=$optarg
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --ve)
            optarg="${PARAM[$i+1]}"
            if [[ -n "$(eval echo \${CURLOPT_${optarg}[*]})" ]]; then
                eval "PARAM+=(\"\${CURLOPT_${optarg}[@]}\")"
            fi
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --vp)
            optarg="${PARAM[$i+1]}"
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                PORT=":$optarg"
            fi
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --verbose)
            VERBOSE=1
            ;;
    esac
    let i++
done
PARAM=("${PARAM[@]}")

if [ ${#PARAM[@]} -eq 0 ]; then
    usage_exit
fi

if [ -n "${CONNECT}" ]; then
    PARAM=("--connect-to" "::${CONNECT}${PORT}" "${PARAM[@]}")
fi

#-------------------------

if [ ${VERBOSE} -eq 1 ]; then
    echo '#curl.sh######################' >&2
    if [ -n "${CONNECT}" ]; then
    printf "%15s | %s\n" "Target Server" "${CONNECT}${PORT}" >&2
    fi
    printf "%15s | %s\n" "Command" "curl ${PARAM[*]}" >&2
    echo '##############################' >&2
    echo >&2
fi

curl "${PARAM[@]}"

