#!/bin/bash
#
# This script is always run whenever the docker image is run, and any extra
# arguments passed on the docker command line are passed in.
#
# This script was inspired by https://github.com/sdt/docker-raspberry-pi-cross-compiler

if [ "${DEBUG}" != "" ]; then
    echo "=================================================="
    echo "USER_UID = ${USER_UID}"
    echo "USER_GID = ${USER_GID}"
    echo "USER_NAME = ${USER_NAME}"
    echo "USER_GROUP = ${USER_GROUP}"
    echo "USER_HOME = ${USER_HOME}"
    echo "USER_PWD = ${USER_PWD}"
    echo "=================================================="

    set -x
fi

chmod 0755 /root

if [[ -n "${USER_UID}" ]] && [[ -n "${USER_GID}" ]]; then
    # Give the user sudo access
    echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME}
    # Add a user and group so that the bash prompt looks reasonable
    groupadd -o -g "${USER_GID}" "${USER_GROUP}" 2> /dev/null
    useradd -o -m -d "${USER_HOME}" -g "${USER_GID}" -G arduino -u "${USER_UID}" "${USER_NAME}" 2> /dev/null
    cd "${USER_PWD}"
    if [ "${USER_DEBUG}" != "" ]; then
        echo "Running as ${USER_NAME}:${USER_GROUP} as ${USER_UID}:${USER_GID}"
    fi

    # When the arduino-cli was installed in the docker image, it created it's data
    # directory in /root/.arduino* The group sticky bit was set, so anybody who
    # belongs to the arduino group will have access.
    ARDUINO_CLI_DATA_DIR="$(cd /root && echo .arduino*)"
    ln -s "/root/${ARDUINO_CLI_DATA_DIR}" "${USER_HOME}/${ARDUINO_CLI_DATA_DIR}"

    chown -R "${USER_UID}:${USER_GID}" "${USER_HOME}" # Give the current user ownship of the home directory

    # The installed /root/.arduino15/arduino-cli.yaml has paths that point to /root
    # Change these to point to the users home directory instead. Otherwise, it will be
    # looking in /root/Arduino instead of ${USER_HOME}/Arduino
    sed -i "s=/root=${USER_HOME}=g" ${USER_HOME}/${ARDUINO_CLI_DATA_DIR}/arduino-cli.yaml

    if [[ $# == 0 ]]; then
        # No arguments passed in. We'll act as if the user entered `bash`
        HOME="${USER_HOME}" exec chpst -u ":${USER_UID}:${USER_GID}:${ARDUINO_GID}" bash
    else
        HOME="${USER_HOME}" exec chpst -u ":${USER_UID}:${USER_GID}:${ARDUINO_GID}" "$@"
    fi
else
    if [ "${USER_DEBUG}" != "" ]; then
        echo "Running as root"
    fi
    if [[ $# == 0 ]]; then
        # No arguments passed in. We'll act as if the user entered `bash`
        exec bash
    else
        exec "$@"
    fi
fi
