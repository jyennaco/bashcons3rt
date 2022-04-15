#!/bin/bash
#
# asset.sh
#
# Common high-use variables and functions that can be called from a CONS3RT asset to aide in the installation
# processes
#
#

# Timestamp functions
function timestamp() { date "+%F %T"; }
function timestamp_formatted() { date "+%F_%H%M%S"; }

# Logging functions
function logInfo() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}"; echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${logFile}; }
function logWarn() { echo -e "$(timestamp) ${logTag} [WARN]: ${1}"; echo -e "$(timestamp) ${logTag} [WARN]: ${1}" >> ${logFile}; }
function logErr() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}"; echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${logFile}; }

function log_info() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}"; echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${logFile}; }
function log_warn() { echo -e "$(timestamp) ${logTag} [WARN]: ${1}"; echo -e "$(timestamp) ${logTag} [WARN]: ${1}" >> ${logFile}; }
function log_err() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}"; echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${logFile}; }

function move_asset_media_to_dir() {
    # WORK IN PROGRESS
    # This function moves asset media files to the specified directory
    # Arg: 1 - full path to the asset media directory
    # Arg: 2 - full path to the directory to move media files to
    # The media files are removed from the asset directory in the process
    local mediaDir="${1}"
    local destinationDir="${2}"
    if [ -z "${mediaDir}" ]; then logErr "move_asset_media_to_dir requires 2 args, path to the asset media and destination directories"; return 1; fi
    if [ -z "${destinationDir}" ]; then logErr "move_asset_media_to_dir requires 2 args, path to the asset media and destination directories"; return 1; fi

    # Ensure the media directory exists
    if [ ! -d ${mediaDir} ]; then
        logErr "Asset media directory not found: ${mediaDir}"
        return 1
    fi

    # Create the destination directory if it does not exist
    if [ ! -d ${destinationDir} ]; then
        logInfo "Creating directory: ${destinationDir}"
        mkdir -p ${destinationDir} >> ${logFile} 2>&1
        if [ $? -ne 0 ]; then logErr "Problem creating destination directory: ${destinationDir}"; return 1; fi
    fi

    logInfo "Moving media from [${mediaDir}] to [${destinationDir}]..."
    mv -f ${mediaDir}/* ${destinationDir}/ >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem moving media from [${mediaDir}] to [${destinationDir}]"; return 1; fi
    logInfo "Completed moving asset media files"
    return 0
}

function read_deployment_properties() {
    if [ -z "${DEPLOYMENT_HOME}" ]; then set_deployment_home; fi
    if [ -z "${DEPLOYMENT_HOME}" ]; then logErr "Problem setting DEPLOYMENT_HOME, unable to read deployment properties files"; return 1; fi
    local deploymentPropertiesFile="${DEPLOYMENT_HOME}/deployment-properties.sh"
    if [ ! -f ${deploymentPropertiesFile} ] ; then
        logErr "Deployment properties file not found: ${deploymentPropertiesFile}"
        return 1
    fi
    logInfo "Reading properties file: ${deploymentPropertiesFile}"
    . ${deploymentPropertiesFile}
    return $?
}

function run_and_check_status() {
    "$@" >> ${logFile} 2>&1
    local status=$?
    if [ ${status} -ne 0 ] ; then
        logErr "Error executing: $@, exited with code: ${status}"
    else
        logInfo "$@ executed successfully and exited with code: ${status}"
    fi
    resultSet+=("${status}")
    return ${status}
}

function set_asset_dir() {
    # Ensure ASSET_DIR exists, if not assume this script exists in ASSET_DIR/scripts
    # Args: Directory of the asset script -- must be determined in the asset
    local runningScriptDir="${1}"
    if [ -z "${runningScriptDir}" ]; then logErr "Must provide 1 arg: the current script directory"; return 1; fi
    if [ -z "${ASSET_DIR}" ] ; then
        logInfo "ASSET_DIR not found, assuming ASSET_DIR is 1 level above this script ..."
        export ASSET_DIR="${runningScriptDir}/.."
    fi
    mediaDir="${ASSET_DIR}/media"
}

function set_cons3rt_role_name() {
    if [ -z "${CONS3RT_ROLE_NAME}" ]; then logErr "CONS3RT_ROLE_NAME is required but not set"; return 1; fi
    # Set the CONS3RT_ROLE_NAME to the environment permanently
    if [ ! -f /etc/profile.d/cons3rt_role_name.sh ]; then
        if [[ "$(whoami)" == "root" ]]; then
            echo "Creating file: /etc/profile.d/cons3rt_role_name.sh"
            echo "export CONS3RT_ROLE_NAME=\"${CONS3RT_ROLE_NAME}\"" > /etc/profile.d/cons3rt_role_name.sh
            chmod 644 /etc/profile.d/cons3rt_role_name.sh
        fi
    fi
    return 0
}

function set_deployment_home() {
    # Ensure DEPLOYMENT_HOME exists
    if [ -z "${DEPLOYMENT_HOME}" ] ; then
        logInfo "DEPLOYMENT_HOME is not set, attempting to determine..."
    else
        return 0
    fi

    local deploymentDirCount=$(ls /opt/cons3rt-agent/run | grep Deployment | wc -l)

    # Ensure only 1 deployment directory was found
    if [ ${deploymentDirCount} -ne 1 ] ; then
        logErr "Could not determine DEPLOYMENT_HOME"
        return 1
    fi

    # Get the full path to deployment home
    local deploymentDir=$(ls /opt/cons3rt-agent/run | grep "Deployment")
    local deploymentHome="/opt/cons3rt-agent/run/${deploymentDir}"

    # Set the environment file if not already
    if [ ! -f /etc/profile.d/cons3rt_deployment_home.sh ]; then
        if [[ "$(whoami)" == "root" ]]; then
            echo "Creating file: /etc/profile.d/cons3rt_deployment_home.sh"
            echo "export DEPLOYMENT_HOME=\"${deploymentHome}\"" > /etc/profile.d/cons3rt_deployment_home.sh
            chmod 644 /etc/profile.d/cons3rt_deployment_home.sh
        fi
    fi
    export DEPLOYMENT_HOME="${deploymentHome}"
    return 0
}
