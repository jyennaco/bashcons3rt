#!/bin/bash
#
# aws_bootstrap.sh
#
# Download and execute this scrip from AWS user-data in order to allow passwords in sshd_config
#
# Usage:
#     curl -O https://path/to/aws_bootstrap.sh
#     chmod +x aws_bootstrap.sh
#     nohup ./aws_bootstrap.sh &
#
#

if [ -f /etc/bashrc ] ; then
    . /etc/bashrc
fi
if [ -f /etc/profile ] ; then
    . /etc/profile
fi

# Times to wait and maximum checks
seconds_between_checks=5
maximum_checks=120

# Timestamp functions for convenience
function timestamp() { date "+%F %T"; }
function timestamp_formatted() { date "+%F_%H%M%S"; }

# Log file location
logFile="/var/log/aws_bootstrap_$(timestamp_formatted).log"

# Logging function
function logInfo() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}"; echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${logFile}; }
function logErr() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}"; echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${logFile}; }

# Configure sshd
function config_sshd() {
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

# Wait for user-data to complete
function wait() {
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
            fi
        fi
        logInfo "Waiting ${seconds_between_checks} seconds to re-check..."
        sleep ${seconds_between_checks}s
        ((check_num++))
    done
}

function main() {
    logInfo "Running: aws_bootstrap.sh"
    wait
    logInfo "Completed: aws_bootstrap.sh"
}

main
logInfo "Exiting with code: 0"
exit 0
