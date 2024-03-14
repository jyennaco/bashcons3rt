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

    # Remove references from /etc/bashrc or /etc/profile
    if [ -f /etc/bashrc ]; then
        echo "INFO: Cleaning out references from: /etc/bashrc"
        sed -i "/# bash cons3rt library/d" /etc/bashrc
        sed -i "/bash_cons3rt.sh/d" /etc/bashrc
    fi
    if [ -f /etc/profile ]; then
        echo "INFO: Cleaning out references from: /etc/profile"
        sed -i "/# bash cons3rt library/d" /etc/profile
        sed -i "/bash_cons3rt.sh/d" /etc/profile
    fi

    # Check and remove the bash cons3rt lib directory
    if [ -d /usr/local/bashcons3rt ]; then
        echo "INFO: Removing bash cons3rt lib directory: /usr/local/bashcons3rt"
        rm -Rf /usr/local/bashcons3rt
        if [ $? -ne 0 ]; then echo "ERROR: Removing bash cons3rt lib directory: /usr/local/bashcons3rt"; return 1; fi
    else
        echo "INFO: Bash cons3rt lib directory does not exist, nothing to remove: /usr/local/bashcons3rt"
    fi

    # Clean up profile.d scripts
    if [ -f /etc/profile.d/cons3rt_role_name.sh ]; then
        echo "INFO: Deleting profile.d script: /etc/profile.d/cons3rt_role_name.sh"
        rm -f /etc/profile.d/cons3rt_role_name.sh
    fi
    if [ -f /etc/profile.d/cons3rt_deployment_home.sh ]; then
        echo "INFO: Deleting profile.d script: /etc/profile.d/cons3rt_deployment_home.sh"
        rm -f /etc/profile.d/cons3rt_deployment_home.sh
    fi
    if [ -f /etc/profile.d/cons3rt_deployment_run_home.sh ]; then
        echo "INFO: Deleting profile.d script: /etc/profile.d/cons3rt_deployment_run_home.sh"
        rm -f /etc/profile.d/cons3rt_deployment_run_home.sh
    fi
    if [ -f /etc/profile.d/cons3rt_created_user.sh ]; then
        echo "INFO: Deleting profile.d script: /etc/profile.d/cons3rt_created_user.sh"
        rm -f /etc/profile.d/cons3rt_created_user.sh
    fi

    logInfo "Completed uninstalling bash cons3rt"
    return 0
}
