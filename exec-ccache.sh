#!/usr/bin/env bash

#
# Hostname in SC BM: get my IP and replace dots with dashes
# HOSTNAME="$(http_proxy='' curl -s http://10.159.25.221:3000 | sed -e 's/[.]/-/g')"
#

usage()
{
    cat <<USAGE
$0 -h hostname -i interval -u user

    -h 		Hostname. If not set, default for collectd or \$(hostname) will be used
    -i 		Interval. Defaults to 60 seconds
    -u 		User for who ccache is monitored. By default - user who runs collectd
    --check     Self check
    --help      This screen
USAGE
}

check()
{
    local REQUIREMENTS=(bc awk)
    local STATUS=0

    for BINARY in ${REQUIREMENTS[*]}; do
	echo -n "Checking for ${BINARY}... "

	if ! which ${BINARY} 2> /dev/null; then
	    echo "not found!"
	    STATUS=1
	fi
    done

    exit ${STATUS}
}

# Defaults:
HOSTNAME=${COLLECTD_HOSTNAME:-$(hostname)}
INTERVAL=${COLLECTD_INTERVAL:-60}
PLUGINUSER=$(id -un)

OPTS=$(getopt -n "$(basename "${0}")" -o 'i:u:h:' -l 'check,help' -- "$@")

eval set -- "$OPTS"

while true; do
    case "$1" in
	-h)
	    HOSTNAME=$2
	    shift 2;;
	-i)
	    INTERVAL=$2
	    shift 2;;
	-u)
	    PLUGINUSER=$2
	    shift 2;;
	--check)
	    check
	    exit;;
	--help)
	    usage
	    exit;;
	--)
	    shift
	    break;;
	*)
	    usage
	    exit 1;;
    esac
done

IDENTIFIER="${HOSTNAME}/exec-ccache"
[[ ${PLUGINUSER} == $(id -un) ]] && SUDO_CMD="" || SUDO_CMD="sudo -u ${PLUGINUSER}"

while true; do
    CCACHE_STATS=$(${SUDO_CMD} ccache -s)

    if [ $? -ne 0 ]; then
	echo "Error executing sudo -u ${PLUGINUSER}, aborting" >&2
	exit 2
    fi

    CCACHE_SIZE_VALUE=$(echo "${CCACHE_STATS}" | grep '^cache size' | awk '{print $3}')
    CCACHE_SIZE_UNIT=$(echo "${CCACHE_STATS}" | grep '^cache size' | awk '{print $4}')

    case "${CCACHE_SIZE_UNIT}" in
	TB|Tbytes)
	    multiplier=1000000000000;;
	GB|Gbytes)
	    multiplier=1000000000;;
	MB|Mbytes)
	    multiplier=1000000;;
	KB|Kbytes)
	    multiplier=1000;;
	*)
	    multiplier=1;;
    esac

    CCACHE_SIZE_VALUE=$(echo "${CCACHE_SIZE_VALUE} * ${multiplier}" | bc -q)
    echo "PUTVAL ${IDENTIFIER}/ccache_size-used interval=${INTERVAL} N:${CCACHE_SIZE_VALUE%%.*}"

    sleep "${INTERVAL}"
done
