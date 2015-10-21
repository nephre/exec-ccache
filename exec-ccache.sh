#!/usr/bin/env bash

#
# Hostname in SC BM: get my IP and replace dots with dashes
# HOSTNAME="$(http_proxy='' curl -s http://10.159.25.221:3000 | sed -e 's/[.]/-/g')"
#

usage()
{
    cat <<USAGE
$0 -h hostname -i interval -u user

    -h 		Hostname. If not set, default for collectd will be used
    -i 		Interval. Defaults to 60 seconds
    -u 		User. By default - user who runs collectd
USAGE
}

# Defaults:
HOSTNAME=${COLLECTD_HOSTNAME:-localhost}
INTERVAL=${COLLECTD_INTERVAL:-60}
PLUGINUSER=$(id -un)

OPTS=$(getopt -n "$(basename "${0}")" -o 'i:u:h:' -l 'help' -- "$@")

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

while true; do
    CCACHE_STATS=$(sudo -u "${PLUGINUSER}" ccache -s)

    if [ $? -ne 0 ]; then
	echo "Error executing sudo -u ${PLUGINUSER}, aborting" >&2
	exit 2
    fi

    CCACHE_SIZE_VALUE=$(echo "$CCACHE_STATS" | grep '^cache size' | awk '{print $3}')
    CCACHE_SIZE_UNIT=$(echo "$CCACHE_STATS" | grep '^cache size' | awk '{print $4}')

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
