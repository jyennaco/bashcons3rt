#!/bin/bash
#
# Source this script in your ~/.bash_profile or /etc/bash_profile to load the bash cons3rt libraries
#
# Usage:
#     . /path/to/bash_cons3rt.sh
#

# Export global variables
export currentDir=$(pwd)
export currentUser=$(whoami)
if [ "${currentUser}" == "root" ]; then
    export logDir='/opt/cons3rt-agent/log'
else
    export logDir="${HOME}/cons3rt-agent/log"
fi
mkdir -p ${logDir}
export logTag='bash_cons3rt'
export logFile="${logDir}/${logTag}.log"
export resultSet=()

# Determine the location of the bash cons3rt library
export BASH_CONS3RT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load functions from bash cons3rt scripts
. ${BASH_CONS3RT_DIR}/asset.sh
. ${BASH_CONS3RT_DIR}/distro.sh
. ${BASH_CONS3RT_DIR}/network.sh
. ${BASH_CONS3RT_DIR}/packages.sh
. ${BASH_CONS3RT_DIR}/python.sh
. ${BASH_CONS3RT_DIR}/systemd.sh
. ${BASH_CONS3RT_DIR}/users.sh

# Initialize the environment
set_cons3rt_role_name
set_deployment_home
set_deployment_run_home
set_cons3rt_created_user
