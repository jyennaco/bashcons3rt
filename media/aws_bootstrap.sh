#!/bin/bash
#
# aws_bootstrap.sh
#
# Download and execute this scrip from AWS user-data in order to allow passwords in sshd_config
#
# Usage:
#     curl -O https://raw.githubusercontent.com/jyennaco/bashcons3rt/master/media/aws_bootstrap.sh
#     chmod +x aws_bootstrap.sh
#     First time running use the setup arg:
#     ./aws_bootstrap.sh setup
#
#     Start the service with:
#     systemctl start aws_bootstrap.service
#

# 1st arg setup, set to "setup" to tell the script to set itself up as a service
SETUP="${1}"

# Source the environment
if [ -f /etc/bashrc ] ; then
    . /etc/bashrc
fi
if [ -f /etc/profile ] ; then
    . /etc/profile
fi

# Times to wait and maximum checks
seconds_between_checks=5
maximum_checks=240

# Path to systemctl service
bootstrapServiceFile='/usr/lib/systemd/system/aws_bootstrap.service'

# Path to the script to execute
scriptPath='/usr/local/bin/aws_bootstrap.sh'

# Parent Directory where this script lives
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Timestamp functions for convenience
function timestamp() { date "+%F %T"; }

# Log file location
logFile="/var/log/aws_bootstrap_service.log"

# Logging function
function logInfo() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}"; echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${logFile}; }
function logErr() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}"; echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${logFile}; }

function config_sshd() {
    # Configure sshd to allow root login, password authentication, and pubkey authentication
    logInfo "Configuring /etc/ssh/sshd_config to allow public key authentication, password authentication, and root login..."
    sed -i '/PubkeyAuthentication/d' /etc/ssh/sshd_config
    sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
    sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
    echo -e "PubkeyAuthentication yes\n" >> /etc/ssh/sshd_config
    echo -e "PermitRootLogin yes\n" >> /etc/ssh/sshd_config
    echo -e "PasswordAuthentication yes\n" >> /etc/ssh/sshd_config

    logInfo "Restarting sshd..."
    systemctl restart sshd.service >> ${logFile} 2>&1
    restartRes=$?
    logInfo "Command [systemctl restart sshd.service] exited with code: ${restartRes}"
    return ${restartRes}
}

function run() {
    # Run the ssh configuration for user-data to complete
    logInfo "Checking the PasswordAuthentication value in /etc/ssh/sshd_config..."
    check_num=1
    while :; do
        if [ ${check_num} -gt ${maximum_checks} ]; then
            logInfo "Maximum number of checks reached ${check_num}, exiting..."
            return 0
        fi
        logInfo "Check number [${check_num} of ${maximum_checks}]"
        passAuthValue=$(cat /etc/ssh/sshd_config | grep "^PasswordAuthentication.*$" | awk '{print $2}')
        if [ -z "${passAuthValue}" ]; then
            logInfo "PasswordAuthentication value not found in /etc/ssh/sshd_config, configuring sshd..."
            config_sshd
        else
            logInfo "Found PasswordAuthentication value in /etc/ssh/sshd_config set to: ${passAuthValue}"
            if [[ "${passAuthValue}" == "no" ]]; then
                logInfo "PasswordAuthentication set to no, configuring sshd..."
                config_sshd
            elif [[ "${passAuthValue}" == "yes" ]]; then
                logInfo "PasswordAuthentication set to yes, nothing to do..."
            else
                logInfo "PasswordAuthentication set to ${passAuthValue}, configuring sshd..."
                config_sshd
                if [ $? -ne 0 ]; then logErr "Problem detected configuring sshd"; fi
            fi
        fi
        logInfo "Waiting ${seconds_between_checks} seconds to re-check..."
        sleep ${seconds_between_checks}s
        ((check_num++))
    done
    return 0
}

function setup() {
    # Configures the aws_bootstrap.service in systemd
    # Return 0 if setup completed with success
    # Return 1 if a problem was detected

    logInfo "Staging this script to: ${scriptPath}"

    # Ensure this script exists
    if [ ! -f ${SCRIPT_DIR}/aws_bootstrap.sh ]; then
        logErr "This script was not found! ${SCRIPT_DIR}/aws_bootstrap.sh"
        return 1
    fi

    # Stage the script
    cp -f ${SCRIPT_DIR}/aws_bootstrap.sh ${scriptPath} >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem staging script from ${SCRIPT_DIR}/aws_bootstrap.sh to: ${scriptPath}"; return 1; fi

    # Set permissions
    logInfo "Setting permissions on: ${scriptPath}"
    chown root:root ${scriptPath} >> ${logFile} 2>&1
    chmod 700 ${scriptPath} >> ${logFile} 2>&1

    logInfo "Staging the aws_bootstrap service file: ${bootstrapServiceFile}"

cat << "EOF" > ${bootstrapServiceFile}
##aws_bootstrap.service
[Unit]
Description=Configures sshd
After=network.target
DefaultDependencies=no
[Service]
Type=simple
ExecStart=/bin/bash ${scriptPath}
User=root
Group=wheel
TimeoutStartSec=0
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

    # Daemon reload to pick up the service change
    logInfo "Running [systemctl daemon-reload] to pick up the new service..."
    systemctl daemon-reload >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem running [systemctl daemon-reload]"; return 1; fi

    # Enable the service
    logInfo "Enabling the aws_bootstrap.service..."
    systemctl enable aws_bootstrap.service >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem enabling the aws_bootstrap.service"; return 1; fi

    # Start the service
    logInfo "Starting the aws_bootstrap.service..."
    systemctl start aws_bootstrap.service >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem starting the aws_bootstrap.service"; return 1; fi

    logInfo "Started aws_bootstrap successfully"
    return 0
}

function main() {
    logInfo "Running: ${SCRIPT_DIR}/aws_bootstrap.sh"
    if [ -z "${SETUP}" ]; then
        logInfo "Running the aws bootstrap service..."
        run
        logInfo "Completed running the AWS bootstrap service."
    else
        if [[ "${SETUP}" == "setup" ]]; then
            setup
            if [ $? -ne 0 ]; then logErr "Problem detected with aws_bootstrap service setup"; return 1; fi
        else
            logErr "Unknown arg provided: ${SETUP}.  Expected nothing or setup"
            return 2
        fi
    fi
    logInfo "Completed: aws_bootstrap.sh"
    return 0
}

# Run the main function
main
res=$?
logInfo "Exiting with code: ${res}"
exit ${res}
