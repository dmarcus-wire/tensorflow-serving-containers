#!/bin/bash

# set environment variables
set -e
USERNAME=$1
SSHFS_PATH=”/usr/bin/sshfs”
MOUNT_POINT=”/var/vmhost”
VAR_VM_HOST_AUTOMOUNT_UNIT=”var-vmhost.automount”
VAR_VM_HOST_AUTOMOUNT_PATH=”/etc/systemd/system/${VAR_VM_HOST_AUTOMOUNT_UNIT}”
VAR_VM_HOST_UNIT=”var-vmhost.mount”
VAR_VM_HOST_PATH=”/etc/systemd/system/${VAR_VM_HOST_UNIT}”
SSH_DIR=/root/.ssh
SSH_PUBLIC_KEY_PATH=”${SSH_DIR}/id_rsa.pub”
SSH_PRIVATE_KEY_PATH=”${SSH_DIR}/id_rsa”

echo “Mount point is ${MOUNT_POINT}”
[ ! -f ${SSHFS_PATH} ] && echo “Installing sshfs” && rpm-ostree install sshfs — allow-inactive

echo “Creating mount point”
mkdir -p ${MOUNT_POINT}
[ ! -f ${SSH_PUBLIC_KEY_PATH} ] && echo “Generating SSH Key” && mkdir -p ${SSH_DIR} && cd ${SSH_DIR} && ssh-keygen -t rsa -f ${SSH_PRIVATE_KEY_PATH} -b 2048 -q -N “”
[ ! -f ${VAR_VM_HOST_AUTOMOUNT_PATH} ] && echo “Creating systemd automount” && cat << EOF > ${VAR_VM_HOST_AUTOMOUNT_PATH}
[Unit]
Description=Podman VM host automounter
[Automount]
Where=${MOUNT_POINT}
DirectoryMode=0755
[Install]
WantedBy=multi-user.target
EOF
chmod 0644 ${VAR_VM_HOST_AUTOMOUNT_PATH}
[ ! -f ${VAR_VM_HOST_PATH} ] && echo “Creating systemd mount” && cat << EOF > ${VAR_VM_HOST_PATH}
[Unit]
Description=Podman VM host mount
[Mount]
What=${USERNAME}@192.168.126.1:/Users/${USERNAME}
Where=${MOUNT_POINT}
Type=fuse.sshfs
Options=user,uid=1000,gid=1000,allow_other,IdentityFile=${SSH_PRIVATE_KEY_PATH},StrictHostKeyChecking=no,exec
[Install]
WantedBy=multi-user.target
EOF
chmod 0644 ${VAR_VM_HOST_PATH}
echo “Enabling systemd automount”
systemctl enable ${VAR_VM_HOST_AUTOMOUNT_UNIT}
echo “Starting systemd automount”
systemctl start ${VAR_VM_HOST_AUTOMOUNT_UNIT}
