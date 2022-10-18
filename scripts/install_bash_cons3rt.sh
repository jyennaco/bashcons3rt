#!/bin/bash

# Source the environment
if [ -f /etc/bashrc ] ; then
    . /etc/bashrc
fi
if [ -f /etc/profile ] ; then
    . /etc/profile
fi

# Establish a log file and log tag
logTag="install_bash_cons3rt"
logDir="/opt/cons3rt-agent/log"
logFile="${logDir}/${logTag}-$(date "+%Y%m%d-%H%M%S").log"

######################### GLOBAL VARIABLES #########################

# Asset media directory
mediaDir=

# Lib directory to install files to
libInstallDir='/usr/local/bashcons3rt'

####################### END GLOBAL VARIABLES #######################

# Logging functions
function timestamp() { date "+%F %T"; }
function logInfo() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${logFile}; }
function logWarn() { echo -e "$(timestamp) ${logTag} [WARN]: ${1}" >> ${logFile}; }
function logErr() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${logFile}; }

function add_env() {
    # Get the globalEnvFile based on what is available
    if [ -f /etc/bashrc ]; then
        globalEnvFile='/etc/bashrc'
    elif [ -f /etc/profile ]; then
        globalEnvFile='/etc/profile'
    else
        logErr "Global env file not found"
        return 1
    fi

    logInfo "Adding the bash_cons3rt library to the environment for all users"
    sed -i "/# bash cons3rt library/d" ${globalEnvFile}
    sed -i "/bash_cons3rt.sh/d" ${globalEnvFile}
    echo -e "\n# bash cons3rt library" >> ${globalEnvFile}
    echo ". ${libInstallDir}/bash_cons3rt.sh" >> ${globalEnvFile}
    echo -e "\n" >> ${globalEnvFile}
    logInfo "Completed adding the bash cons3rt lib to the environment for all users"
    return 0
}

function set_asset_dir() {
    # Ensure ASSET_DIR exists, if not assume this script exists in ASSET_DIR/scripts
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [ -z "${ASSET_DIR}" ] ; then
        logWarn "ASSET_DIR not found, assuming ASSET_DIR is 1 level above this script ..."
        export ASSET_DIR="${SCRIPT_DIR}/.."
    fi
    mediaDir="${ASSET_DIR}/media"
}

function run_initial_bash_cons3rt() {
    logInfo "Running the initial bash cons3rt..."
    ${libInstallDir}/bash_cons3rt.sh >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem running: ${libInstallDir}/bash_cons3rt.sh"; return 1; fi
}

function stage_bash_cons3rt_libs() {
    # Create the library directory
    if [ ! -d ${libInstallDir} ]; then
        logInfo "Creating directory: ${libInstallDir}"
        mkdir -p ${libInstallDir} >> ${logFile} 2>&1
        if [ $? -ne 0 ]; then logErr "Problem creating directory: ${libInstallDir}"; return 1; fi
    fi

    # Set permissions on the library directory
    logInfo "Setting permissions on: ${libInstallDir}"
    chmod 755 ${libInstallDir} >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem setting permissions on directory: ${libInstallDir}"; return 1; fi

    # Stage the library files
    logInfo "Staging library files to: ${libInstallDir}"
    cp -f ${mediaDir}/* ${libInstallDir}/ >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem staging file from ${mediaDir} to directory: ${libInstallDir}"; return 1; fi

    # Set permissions to allow all users
    logInfo "Setting permissions on files in ${libInstallDir}/"
    chmod 755 ${libInstallDir}/*.sh >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem setting permissions on files in directory: ${libInstallDir}"; return 1; fi

    logInfo "Completed staging bash cons3rt lib files"
    return 0
}

function verify_prerequisities() {
    logInfo "Verifying prerequisites..."
    if [ -z "${CONS3RT_ROLE_NAME}" ]; then logErr "CONS3RT_ROLE_NAME is required but not set"; return 1; fi
    return 0
}

function main() {
    logInfo "Running asset install: ${logTag}"
    verify_prerequisities
    if [ $? -ne 0 ]; then logErr "Problem verifying prerequisites"; return 1; fi
    set_asset_dir
    stage_bash_cons3rt_libs
    if [ $? -ne 0 ]; then logErr "Problem staging bash cons3rt library files"; return 2; fi
    add_env
    if [ $? -ne 0 ]; then logErr "Problem adding bash cons3rt to the environment for all users"; return 3; fi
    run_initial_bash_cons3rt
    if [ $? -ne 0 ]; then logErr "Problem running the initial bash cons3rt"; return 4; fi
    logInfo "Successfully completed: ${logTag}"
    return 0
}

# Set up the log file
mkdir -p ${logDir}
chmod 700 ${logDir}
touch ${logFile}
chmod 644 ${logFile}
main
result=$?
logInfo "Exiting with code ${result} ..."
cat ${logFile}
exit ${result}
