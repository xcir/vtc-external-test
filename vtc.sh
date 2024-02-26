#!/bin/bash

usage_exit() {
  cat << EOF 1>&2
Usage: $0 [-h] [-v] [-s] [-f] [-n target name] [-c connection server] [-o extra varnishtest option] [vtc_file or vtc_dir]
    -s Entering docker container shell
    -f Force rebuild docker image
    -h Show this help
    -v Enable verbose mode
Example: $0 -c example.net tests/example.vtc
EOF
  exit 1
}

docker_build() {
    if [ "$(docker image ls -q "$DOCKER_IMAGE_NAME")" ]; then
        if [ -n "${FORCE_REBUILD}" ]; then
            docker rmi $DOCKER_IMAGE_NAME
        else
            return
        fi
    fi
    docker build --rm -t $DOCKER_IMAGE_NAME -f Dockerfile .
}

#------------------------------------------------------------

SCRIPT_DIR=$(cd $(dirname $0); pwd)
source ${SCRIPT_DIR}/conf.sh

while getopts sfhvn:c:o: OPT
do
    case $OPT in
        h)  usage_exit;;
        s)  EXECSHELL=1;;
        f)  FORCE_REBUILD=1;;
        v)  VERBOSE=" -v";;
        c)  CONNECT=$OPTARG;;
        n)  TGNAME=$OPTARG;;
        o)  VTCOPT=$OPTARG;;
    esac
done
shift $((OPTIND - 1))

if [[ -z "${CONNECT}" ]]; then
    if [[ -n "$(eval echo \${C_${TGNAME}})" ]]; then
        CONNECT="$(eval echo \${C_${TGNAME}})"
    else
        CONNECT="${C_default}"
    fi
fi

if [ -z "$1" ]; then
    MNT="$DEFAULT_VTC_DIR:/mnt/tests"
    VTCTG="$DEFAULT_VTC_DIR/*.vtc"
elif [ -e "$1" ]; then
    TG=$(realpath $1)
    if [ -d "$TG" ]; then
        MNT="$TG:/mnt/tests"
        VTCTG="$TG/*.vtc"
    else
        MNT="$TG:/mnt/tests/test.vtc"
        VTCTG="$TG"
    fi
fi

if [[ -z "${CONNECT}" ]]; then
    echo "Target server is not defined."
    usage_exit
fi
if [[ -z "${VTCTG}" ]]; then
    echo "VTC is not defined."
    usage_exit
fi

echo "=============================================="
printf "%15s: %s\n" "Target Server" "${CONNECT}"
printf "%15s: %s\n" "VTC" "${VTCTG}"
if [[ -n "${VTCOPT}" ]]; then
    printf "%15s: %s\n" "VTC Option" "${VTCOPT}"
fi
if [[ -n "${VERBOSE}" ]]; then
    printf "%15s: Enabled\n" "Verbose"
fi
echo "=============================================="

docker_build

if [[ -n "${EXECSHELL}" ]]; then
    docker run --rm \
        -v $MNT \
        -it $DOCKER_IMAGE_NAME \
        /bin/bash
    exit 0
fi

docker run --rm \
    -v $MNT \
    -it $DOCKER_IMAGE_NAME \
    /bin/bash -c "varnishtest ${VERBOSE} -Dtarget=\"${CONNECT}\" ${VTCOPT} -j ${VTC_JOBS} -b ${VTC_BUFFER_SIZE} /mnt/tests/*.vtc"

