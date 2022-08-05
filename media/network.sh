#!/bin/bash
#
# network.sh
#
# Common networking functions
#
#

function get_dns_ip() {
    local domainName="${1}"
    if [ -z "${domainName}" ]; then
        return 1
    fi
    which nslookup >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 1
    fi
    nslookup "${domainName}" | grep 'Address:' | tail -n 1 | awk '{print $NF}'
    return $?
}


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
