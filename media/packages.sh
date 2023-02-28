#!/bin/bash
#
# packages.sh
#
# Common functions that handle updating and installing packages
#
#

azureClientCert='/etc/pki/rhui/product/content-rhel8-eus.crt'
packageInstallCommand=
packageUpdateCommand=

function determine_package_manager() {
    # exports 2 variables packageInstallCommand and packageUpdateCommand
    # Returns 0 if package manager was found and variables exported
    # Returns 1 if package manager was not found
    which dnf >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        packageInstallCommand='dnf --assumeyes install'
        packageUpdateCommand='dnf --assumeyes update'
    else
        which yum >> /dev/null 2>&1
        if [ $? -eq 0 ]; then
            packageInstallCommand='yum -y install'
            packageUpdateCommand='yum -y update'
        fi
    fi
    which apt >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        packageInstallCommand='apt -y install'
        packageUpdateCommand='apt -y update && apt -y upgrade'
    else
        which yum >> /dev/null 2>&1
        if [ $? -eq 0 ]; then
            packageInstallCommand='apt-get -y install'
            packageUpdateCommand='apt-get -y update && apt-get -y upgrade'
        fi
    fi
    if [ -z "${packageInstallCommand}" ]; then
        logWarn "Unable to determine package manager on this system"
        return 1
    fi
    export packageInstallCommand=${packageInstallCommand}
    export packageUpdateCommand${packageUpdateCommand}
    return 0
}

function update_azure_redhat_client_cert() {
    # For Azure only, update the client certificate
    # Return 0 for success or if this is not Azure
    # Return 1 if could not determine the virtualization realm type
    # Return 2 if the update failed

    # Read deployment props
    read_deployment_properties

    # Return 1 if the VR type is not found
    if [ -z "${cons3rt_deploymentRun_virtRealm_type}" ]; then
        logWarn "Unable to determine virtualization realm type, not running Azure client cert udpate steps"
        return 1
    fi

    # Return 0 if this is not Azure
    if [[ "${cons3rt_deploymentRun_virtRealm_type}" != "Azure" ]]; then
        return 0
    fi

    # Run the steps if the Azure client cert exists
    if [ -f ${azureClientCert} ] ; then
        logInfo "Updating the Azure client cert: ${azureClientCert}"
        yum update -y --disablerepo='*' --enablerepo='*microsoft*'
        if [ $? -ne 0 ]; then return 2; fi
        yum clean all
        if [ $? -ne 0 ]; then return 2; fi
        yum makecache
        if [ $? -ne 0 ]; then return 2; fi
    else
        logInfo "Azure client cert not found [${azureClientCert}], nothing to update"
    fi
    return 0
}
