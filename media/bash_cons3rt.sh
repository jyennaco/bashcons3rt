#!/bin/bash
#
# Source this script in your ~/.bash_profile or /etc/bash_profile to load the bash cons3rt libraries
#
# Usage:
#     . /path/to/bash_cons3rt.sh
#

# Export global variables
if [ "$(whoami)" == "root" ]; then
    export CONS3RT_LOG_DIR='/opt/cons3rt-agent/log'
else
    export CONS3RT_LOG_DIR="${HOME}/cons3rt-agent/log"
fi
export CONS3RT_LOG_TAG='bash_cons3rt'
export CONS3RT_LOG_FILE="${CONS3RT_LOG_DIR}/${CONS3RT_LOG_TAG}.log"
export CONS3RT_ASSET_RESULTS=()

# For backwards compatibility
export logTag="${CONS3RT_LOG_TAG}"
export logDir="${CONS3RT_LOG_DIR}"
export logFile="${CONS3RT_LOG_FILE}"

# Determine the location of the bash cons3rt library
export BASH_CONS3RT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load functions from bash cons3rt scripts
. ${BASH_CONS3RT_DIR}/asset.sh
. ${BASH_CONS3RT_DIR}/distro.sh
. ${BASH_CONS3RT_DIR}/network.sh
. ${BASH_CONS3RT_DIR}/packages.sh
. ${BASH_CONS3RT_DIR}/python.sh
. ${BASH_CONS3RT_DIR}/systemd.sh
. ${BASH_CONS3RT_DIR}/uninstall.sh
. ${BASH_CONS3RT_DIR}/users.sh

# Initialize the environment
set_cons3rt_role_name
set_deployment_home
set_deployment_run_home
set_cons3rt_created_user
