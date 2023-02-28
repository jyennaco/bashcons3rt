#!/bin/bash
#
# distro.sh
#
# Common functions for determining and using the Linux distribution, name, ID, and version
#
#

# The linux distro
distroId=
distroVersion=
distroMajorVersion=
distroFamily=

function get_distro() {
    if [ -f /etc/os-release ] ; then
        . /etc/os-release
        if [ -z "${ID}" ] ; then logErr "Linux distro ID not found"; return 1;
        else distroId="${ID}"; fi;
        if [ -z "${VERSION_ID}" ] ; then logErr "Linux distro version ID not found"; return 2
        else distroVersion=$(echo "${VERSION_ID}" | awk -F . '{print $1}'); fi;
        if [ -z "${ID_LIKE}" ] ; then logErr "Linux distro family not found"; return 3
        else distroFamily="${ID_LIKE}"; fi;
    elif [ -f /etc/centos-release ] ; then
        distroId="centos"
        distroVersion=$(cat /etc/centos-release | sed "s|Linux||" | awk '{print $3}' | awk -F . '{print $1}')
        distroFamily="rhel fedora"
    elif [ -f /etc/redhat-release ] ; then
        distroId="redhat"
        distroVersion=$(cat /etc/redhat-release | awk '{print $7}' | awk -F . '{print $1}')
        distroFamily="rhel fedora"
    else logErr "Unable to determine the Linux distro or version"; return 4; fi;
    if [[ ${distroId} == "rhel" ]] ; then
        logInfo "Found distroId: rhel, setting to redhat..."
        distroId="redhat"
    fi
    distroMajorVersion=$(echo ${distroVersion} | awk -F . '{print $1}')
    logInfo "Detected Linux Distro ID: ${distroId}"
    logInfo "Detected Linux Version ID: ${distroVersion}"
    logInfo "Detected Linux major version: ${distroMajorVersion}"
    logInfo "Detected Linux Family: ${distroFamily}"
    export distroId=${distroId}
    export distroVersion=${distroVersion}
    export distroMajorVersion=${distroMajorVersion}
    export distroFamily=${distroFamily}
    return 0
}
