#!/bin/bash
#
# network.sh
#
# Common networking functions
#
#


function validate_ip_address() {
    # Test an IP address for validity
    # Parameters:
    # 1 - IP address to check
    # Returns
    # 0 - IP address is valid
    # non-zero - IP address is invalid
    local ip="$1"
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
