#!/bin/bash
shopt -s nocasematch

SCRIPT_DIR=$(cd $(dirname $0); pwd)
source ${SCRIPT_DIR}/conf.sh

CONNECT=""
PARAM=("${@}")
VERBOSE=0

if [[ "${PARAM[*]}" =~ "https" ]]; then
    PORT=443
else
    PORT=80
fi

i=0
for v in "${PARAM[@]}"; do
    case "$v" in
        --vn)
            #接続先指定
            optarg="${PARAM[$i+1]}"
            if [[ -n "$(eval echo \${C_${optarg}})" ]]; then
                CONNECT="$(eval echo \${C_${optarg}})"
            fi
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --vc)
            #接続先指定(con)
            optarg="${PARAM[$i+1]}"
            CONNECT=$optarg
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --vo)
            #マクロ指定
            optarg="${PARAM[$i+1]}"
            if [[ -n "$(eval echo \${CURLOPT_${optarg}[*]})" ]]; then
                eval "PARAM+=(\"\${CURLOPT_${optarg}[@]}\")"
            fi
            unset PARAM[$((i))]
            unset PARAM[$((i+1))]
            ;;
        --vp)
            #port指定
            optarg="${PARAM[$i+1]}"
            PORT=$optarg
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


if [ -n "${CONNECT}" ]; then
    CONNECTIP=$(dig $CONNECT +short|tail -n1)
    PARAM=("--resolve" "$CONNECT:$PORT:$CONNECTIP" "${PARAM[@]}")
fi

#-------------------------

if [ ${VERBOSE} -eq 1 ]; then
    echo '#curl.sh######################'
    if [ -n "${CONNECT}" ]; then
    printf "%15s | %s\n" "Target Server" "${CONNECT}"
    printf "%15s | %s\n" "Target IP:PORT" "${CONNECTIP}:${PORT}"
    fi
    printf "%15s | %s\n" "Command" "curl ${PARAM[*]}"
    echo '##############################'
    echo
fi

curl "${PARAM[@]}"

