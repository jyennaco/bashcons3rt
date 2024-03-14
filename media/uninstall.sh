#!/bin/bash
#
# uninstall.sh
#
# Functions for uninstalling bash cons3rt
#
#

function uninstall_bash_cons3rt() {
    echo "INFO: Uninstalling bash cons3rt..."

    # Ensure the uninstall is executed by root
    local currentUser=$(whoami)
    if [[ "${currentUser}" == "root" ]]; then
        echo "INFO: Uninstalling bash cons3rt as the root user..."
    else
        echo "ERROR: Please uninstall bash cons3rt as the root user, found: ${currentUser}"
        return 1
    fi

    # Lib directory to install files to
    local libInstallDir='/usr/local/bashcons3rt'

    # Check and remove the bash cons3rt lib directory
    if [ -d ${libInstallDir} ]; then
        echo "INFO: Removing bash cons3rt lib directory: ${libInstallDir}"
        rm -Rf ${libInstallDir}
        if [ $? -ne 0 ]; then echo "ERROR: Removing bash cons3rt lib directory: ${libInstallDir}"; return 1; fi
    else
        echo "INFO: Bash cons3rt lib directory does not exist, nothing to remove: ${libInstallDir}"
    fi

    logInfo "Completed uninstalling bash cons3rt"
    return 0
}
