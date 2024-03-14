#!/bin/bash
#
# python.sh
#
# Common python-related functions
#
#

function install_python3_rootless_virtualenv() {
    logInfo "Configuring the rootless user python3 from online sources..."

    # Upgrade pip to the latest
    logInfo "Upgrading pip to the latest..."
    runuser -l ${CONS3RT_CREATED_USER} -c "${python3Exe} -m pip install --user pip --upgrade" >> ${CONS3RT_LOG_FILE} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem upgrading pip"; return 1; fi

    # Install virtualenv
    logInfo "Install virtualenv..."
    runuser -l ${CONS3RT_CREATED_USER} -c "${python3Exe} -m pip install --user virtualenv" >> ${CONS3RT_LOG_FILE} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem installing virtualenv"; return 1; fi

   # Create the virtual environment
    logInfo "Creating the virtual environment venv in directory: /home/${CONS3RT_CREATED_USER}"
    runuser -l ${CONS3RT_CREATED_USER} -c "cd /home/${CONS3RT_CREATED_USER}; ${python3Exe} -m virtualenv venv" >> ${CONS3RT_LOG_FILE} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem creating the python3 virtual environment"; return 1; fi

    # Ensure the venv exists
    logInfo "Ensuring the virtualenv python3 exists..."
    venvPython3Exe="/home/${CONS3RT_CREATED_USER}/venv/bin/python3"
    if [ ! -f ${venvPython3Exe} ]; then logErr "Virtual environment python3 not found: ${venvPython3Exe}"; return 1; fi

    logInfo "Completed configuring rootless user python3 online"
    return 0
}

function install_python3_rootless_virtualenv_packages() {
    logInfo "Installing packages into the ${CONS3RT_CREATED_USER} python3 virtualenv"

    local python3Packages="${1}"

    # Ensure the venv exists
    logInfo "Ensuring the virtualenv python3 exists..."
    venvPython3Exe="/home/${CONS3RT_CREATED_USER}/venv/bin/python3"
    if [ ! -f ${venvPython3Exe} ]; then logErr "Virtual environment python3 not found: ${venvPython3Exe}"; return 1; fi

    # Install packages
    logInfo "Install python3 packages: [${python3Packages}]"
    runuser -l ${CONS3RT_CREATED_USER} -c "${venvPython3Exe} -m pip install ${python3Packages}" >> ${CONS3RT_LOG_FILE} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem installing python3 packages [${python3Packages}] from online sources"; return 1; fi

    logInfo "Completed installing packages into the ${CONS3RT_CREATED_USER} python3 virtualenv"
    return 0
}
