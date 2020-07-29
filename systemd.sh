

function stop_service() {
    local svcRes=0
    activeStatus=$(systemctl is-active $1)
    if [ -z "${activeStatus}" ]; then logWarn "Unable to determine active status of: $1"; activeStatus="notfound"; fi
    case ${activeStatus} in
        active)
            logInfo "Stopping service: $1"
            systemctl stop $1.service >> ${logFile} 2>&1
            svcRes=$?
            sleep 5
            return ${svcRes}
            ;;
        *)
            logInfo "$1 is not active, found status [${activeStatus}], nothing to do"
            ;;
    esac
    return 0
}

function start_service() {
    local svcRes=0
    activeStatus=$(systemctl is-active $1)
    if [ -z "${activeStatus}" ]; then logWarn "Unable to determine active status of: $1"; activeStatus="notfound"; fi
    case ${activeStatus} in
        active)
            logInfo "Service already active: $1"
            ;;
        *)
            logInfo "Starting service: $1"
            systemctl start $1.service >> ${logFile} 2>&1
            svcRes=$?
            sleep 5
            return ${svcRes}
            ;;
    esac
    return 0
}

function restart_service() {
    logInfo "Restarting service: $1"
    stop_service $1
    start_service $1
    return $?
}

function enable_service() {
    local svcRes=0
    enabledStatus=$(systemctl is-enabled $1)
    if [ -z "${enabledStatus}" ]; then logWarn "Unable to determine enabled status of $1"; enabledStatus="notfound"; fi
    case ${enabledStatus} in
        enabled)
            logInfo "Service already enabled: $1"
            ;;
        *)
            logInfo "Enabling service: $1"
            systemctl enable $1.service >> ${logFile} 2>&1
            svcRes=$?
            sleep 2
            return ${svcRes}
            ;;
    esac
    return 0
}

function disable_service() {
    local svcRes=0
    enabledStatus=$(systemctl is-enabled $1)
    if [ -z "${enabledStatus}" ]; then logWarn "Unable to determine enabled status of $1"; enabledStatus="notfound"; fi
    case ${enabledStatus} in
        enabled)
            logInfo "Disabling service: $1"
            systemctl disable $1.service >> ${logFile} 2>&1
            svcRes=$?
            sleep 2
            return ${svcRes}
            ;;
        *)
            logInfo "$1 is not enabled, found status [${enabledStatus}], nothing to do"
            ;;
    esac
    return 0
}

function remove_service() {
    if [ -f /etc/systemd/system/${1}.service ]; then
        logInfo "Removing: /etc/systemd/system/${1}.service"
        rm -f /etc/systemd/system/${1}.service >> ${logFile} 2>&1
        if [ $? -ne 0 ]; then logErr "Problem removing: rm -f /etc/systemd/system/${1}.service"; return 1; fi
    fi
    if [ -f /usr/lib/systemd/system/${1}.service ]; then
        logInfo "Removing: /usr/lib/systemd/system/${1}.service"
        rm -f /usr/lib/systemd/system/${1}.service >> ${logFile} 2>&1
        if [ $? -ne 0 ]; then logErr "Problem removing: rm -f /usr/lib/systemd/system/${1}.service"; return 2; fi
    fi
    logInfo "Running: systemctl daemon-reload"
    systemctl daemon-reload >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem running: systemctl daemon-reload"; return 3; fi
    logInfo "Running: systemctl reset-failed"
    systemctl reset-failed >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "Problem running: systemctl reset-failed"; return 4; fi
    logInfo "Completed uninstalling: ${1}"
    return 0
}
