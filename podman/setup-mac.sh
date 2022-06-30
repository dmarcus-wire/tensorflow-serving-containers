#!/bin/bash

# set environment variables
set -e
PROVISIONING_SH=”./provision-vm.sh”
VM_NAME=”${1:-podman-machine-default}”
SSH_IDENTITY_PATH=”/root/.ssh/id_rsa”
SSH_DIR=/root/.ssh
LOCAL_SSH_DIR=~/.ssh
SSH_PUBLIC_KEY_PATH=”${SSH_DIR}/id_rsa.pub”
USERNAME=$(id -un)
IP_ADDRESS=”192.168.126.1"
NETWORK_INTERFACE=”en0"
AUTHORIZED_KEYS_FILE=”${LOCAL_SSH_DIR}/authorized_keys”

# configure mac system preferences
echo “Found username: ${USERNAME}”
[ “${USERNAME}” == “root” ] && echo “Please do not run this script as root, run as a normal user without sudo!” && exit 1
echo “Setting remote login on”
sudo systemsetup -setremotelogin on
echo “Assigning IP address”
IFCONFIG_OUTPUT=$(ifconfig)
[ ! “${IFCONFIG_OUTPUT}” == *”${IP_ADDRESS}”* ] && sudo ifconfig ${NETWORK_INTERFACE} alias ${IP_ADDRESS}

echo “Provisioning VM”
podman machine ssh “cat >provision-vm.sh” <provision-vm.sh
podman machine ssh ${VM_NAME} “sudo chmod +x ${PROVISIONING_SH} && sudo ${PROVISIONING_SH} ${USERNAME}”
echo “Getting SSH public key from VM”
SSH_PUB_KEY=$(podman machine ssh ${VM_NAME} “sudo cat ${SSH_PUBLIC_KEY_PATH}”)
echo “Concatenating VM SSH public key to authorized keys”
mkdir -p ${LOCAL_SSH_DIR} && touch ${AUTHORIZED_KEYS_FILE}
AUTHORIZED_KEYS=$(cat ${AUTHORIZED_KEYS_FILE})
[ ! “${AUTHORIZED_KEYS}” == *”${SSH_PUB_KEY}”* ] && echo ${SSH_PUB_KEY} >> ${AUTHORIZED_KEYS_FILE}
