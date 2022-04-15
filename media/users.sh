#!/bin/bash
#
# users.sh
#
# Common functions that handle user operations like managing groups and projects
#
#

function add_user_to_group() {
    username=""
    groupname=""
    username=${1}
    groupname=${2}

    # Ensure a user was provided
    if [ -z "${username}" ] ; then
        logErr "Username not provided to add_user_to_group"
        return 1
    fi

    # Ensure a group was provided
    if [ -z "${groupname}" ] ; then
        logErr "Group name not provided to add_user_to_group"
        return 2
    fi
    logInfo "Attemping to add user [${username}] to group [${groupname}]"

    # Ensure the username exists
    if [ $(id -u ${username} >> /dev/null 2>&1; echo $?) -ne 0 ]; then
        logErr "User does not exist: ${username}"
        return 3
    fi

    # Ensure the groupname exists
    if [ "$(id -g ${groupname} >> /dev/null 2>&1; echo $?)" -eq 0 ] ; then
        logInfo "Found group: ${groupname}"
    else
        if [[ "${groupname}" == "wheel" ]] ; then
            logInfo "This is wheel group"
        else
            logErr "Group does not exist: ${groupname}"
            return 4
        fi
    fi

    # Add the user to the group
    logInfo "Adding user [${username}] to group: [${groupname}]..."
    usermod -a -G ${groupname} ${username} >> ${logFile} 2>&1
    if [ $? -ne 0 ] ; then
        logErr "There was a problem adding user [${username}] to group: [${groupname}]"
        return 5
    else
        logInfo "Successfully added user [${username}] to group: [${groupname}]"
    fi
    return 0
}

function create_group() {
    groupname=""
    group_id=""
    groupname="${1}"
    group_id="${2}"

    # Ensure a group was provided
    if [ -z "${groupname}" ] ; then
        logWarn "groupname not provided to create_group"
        return 1
    fi

    # Create the group if it does not exist
    if [ "$(id -g ${groupname} >> /dev/null 2>&1; echo $?)" -eq 0 ] ; then
        logInfo "${groupname} group already exists"
    else
        logInfo "${groupname} group does not exist, creating ..."
        groupadd ${groupname} >> ${logFile} 2>&1
        if [ $? -ne 0 ] ; then
            logErr "There was a problem creating group: ${groupname}"
            return 1
        else
            logInfo "Successfully created group: ${groupname}"
        fi
    fi

    # Exit if no desired Group ID provided
    if [ -z "${group_id}" ]; then
        logInfo "No desired group ID provided, done creating group: ${groupname}"
        return 0
    fi

    # Attempt to modify the group ID

    # Check for existing group with that GID
    existingGroup=$(getent group ${group_id})

    if [ -z "${existingGroup}" ]; then
        logInfo "No existing group found with UID: ${group_id}"
    else
        logInfo "Found existing group with gID ${group_id}: ${existingGroupexistingUser}"
        existingGroup=$(echo "${existingGroup}" | awk -F : '{print $1}')
        if [[ ${existingGroup} != ${groupname} ]]; then
            logInfo "Found existing group: ${existingGroup} with GID: ${group_id}"
            let new_gid=$group_id+50
            logInfo "Attempting to assign new UID ${new_gid} to user: ${existingGroup}"
            groupmod -g ${new_gid} ${existingGroup} >> ${logFile} 2>&1
            if [ $? -ne 0 ]; then logErr "There was a problem changing the GID of ${existingGroup} to: ${new_gid}"; return 3; fi
        fi
    fi

    logInfo "Attempting to set the group ID for [${groupname}] to: ${group_id}"
    groupmod -g ${group_id} ${groupname} >> ${logFile} 2>&1
    if [ $? -ne 0 ]; then logErr "There was a problem setting the group ID for [${groupname}] to: ${group_id}"; return 2; fi
    logInfo "Successfully set the group ID for [${groupname}] to: ${group_id}"
    return 0
}

function create_user() {
    username="${1}"
    desired_uid="${2}"

    # Ensure a user was provided
    if [ -z "${username}" ] ; then
        logWarn "Username not provided to create_user"
        return 1
    fi

    # Set the homer directory and login shell
    homedir="/home/${username}"
    loginshell="/bin/bash"

    # Create the user
    if [ $(id -u ${username} >> /dev/null 2>&1; echo $?) -ne 0 ]; then
        logInfo "${username} user does not exist yet, creating..."
        useradd -d "${homedir}" -s "${loginshell}" -c "${username}" -g ${username} ${username} >> ${logFile} 2>&1
        if [ $? -ne 0 ] ; then
            logErr "There was a problem creating user: ${username}"
            return 2
        else
            logInfo "Successfully created user: ${username}"
        fi
    else
        logInfo "${username} user already exists"
    fi

    if [ -z "${desired_uid}" ]; then
        logInfo "No desired UID provided"
    else
        logInfo "Desired UID is: ${desired_uid}"

        # Check for existing user with that UID
        existingUser=$(getent passwd ${desired_uid})

        if [ -z "${existingUser}" ]; then
            logInfo "No existing user found with UID: ${desired_uid}"
        else
            existingUsername=$(echo "${existingUser}" | awk -F : '{print $1}')
            if [[ ${existingUsername} != ${username} ]]; then
                logInfo "Found existing user with UID ${desired_uid}: ${existingUser}"
                logInfo "Found existing username: ${existingUsername} with UID: ${desired_uid}"
                let new_uid=$desired_uid+50
                logInfo "Attempting to assign new UID ${new_uid} to user: ${existingUsername}"
                usermod -u ${new_uid} ${existingUsername} >> ${logFile} 2>&1
                if [ $? -ne 0 ]; then logErr "There was a problem changing the UID of ${existingUsername} to: ${new_uid}"; return 3; fi
            fi
        fi

        logInfo "Setting UID for user [${username}] to: ${desired_uid}"
        usermod -u ${desired_uid} ${username} >> ${logFile} 2>&1
        if [ $? -ne 0 ]; then logErr "There was a problem setting UID for username [${username}] to: ${desired_uid}"; return 4; fi
    fi
    logInfo "Completed user creation for: ${username}"
    return 0
}

function set_cons3rt_created_user() {
    # Exit if already set
    if [ -z "${CONS3RT_CREATED_USER}" ]; then
        logInfo "CONS3RT_CREATED_USER not found, attempting to determine..."
    else
        return 0
    fi

    # Ensure the role name variable is set
    if [ -z "${CONS3RT_ROLE_NAME}" ]; then logErr "CONS3RT_ROLE_NAME is required but not set"; return 1; fi
    if [ -z "${DEPLOYMENT_HOME}" ]; then set_deployment_home; fi
    if [ -z "${DEPLOYMENT_HOME}" ]; then logErr "DEPLOYMENT_HOME is required but not set"; return 1; fi

    local deploymentPropertiesFile="${DEPLOYMENT_HOME}/deployment.properties"

    # Get the created user from the role name
    local cons3rtCreatedUsers=( $(cat ${deploymentPropertiesFile} | grep "cons3rt.fap.deployment.machine.createdUsername.${CONS3RT_ROLE_NAME}" | awk -F = '{print $2}') )
    local cons3rtCreatedUser="${cons3rtCreatedUsers[0]}"

    # Ensure the cons3rt-created user was found
    if [ -z "${cons3rtCreatedUser}" ]; then logErr "Unable to determine the CONS3RT-created user from deployment properties"; return 1; fi
    logInfo "Found the CONS3RT-created user: ${cons3rtCreatedUser}"

    # Set the environment file if not already
    if [ ! -f /etc/profile.d/cons3rt_created_user.sh ]; then
        if [[ "$(whoami)" == "root" ]]; then
            echo "Creating file: /etc/profile.d/cons3rt_created_user.sh"
            echo "export CONS3RT_CREATED_USER=\"${cons3rtCreatedUser}\"" > /etc/profile.d/cons3rt_created_user.sh
            chmod 644 /etc/profile.d/cons3rt_created_user.sh
        fi
    fi
    export CONS3RT_CREATED_USER="${cons3rtCreatedUser}"
    return 0
}

function set_user_password() {
    username=""
    user_password=""
    username=${1}
    user_password=${2}

    # Ensure a user was provided
    if [ -z "${username}" ] ; then
        logErr "Username not provided to set_user_password"
        return 1
    fi

    # Ensure a password was provided
    if [ -z "${user_password}" ] ; then
        logErr "user_password not provided to set_user_password"
        return 1
    fi

    # Set the user password
    logInfo "Setting the password for user: ${username}"
    echo "${username}:${user_password}" | chpasswd
    if [ $? -ne 0 ] ; then
        logErr "There was a problem setting password for user: ${username}"
        return 2
    else
        logInfo "Successfully set password for user: ${username}"
    fi

    # Set the password to never expire
    logInfo "Setting the password to never expire for user: ${username}"
    chage -I -1 -m 0 -M 99999 -E -1 ${username} >> ${logFile} 2>&1
    if [ $? -ne 0 ] ; then logErr "There was a problem configuring user to not expire: ${username}"; return 3; fi
    logInfo "Successfully set ${username} to never expire"
    return 0
}
