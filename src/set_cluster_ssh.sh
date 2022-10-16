#!/bin/bash

. common.sh
read_env ".env"

ssh-keygen -f "/home/${LOCAL_USER}/.ssh/known_hosts" -R "${MASTER0_IP}"
echo "${VM_PASSW}" ssh-copy-id ${SSH_OPTS} ${VM_USER}@${MASTER0_IP}
echo -e "\nalias ${MASTER0_NAME}='ssh ${VM_USER}@${MASTER0_IP}'" >> "/home/${LOCAL_USER}/.bashrc"

for idx in "${!WORKERS_IPS[@]}"; do
    worker_name="${WORKERS_NAMES[idx]}"
    worker_ip="${WORKERS_IPS[idx]}"
    echo "Adding alias and for ${worker_name}"
    ssh-keygen -f "/home/${LOCAL_USER}/.ssh/known_hosts" -R "${worker_ip}"
    echo "${VM_PASSW}" ssh-copy-id ${SSH_OPTS} ${VM_USER}@${worker_ip}
    if ! grep -q "${worker_name}" "/home/${LOCAL_USER}/.bashrc"; then
        echo -e "\nalias ${worker_name}='ssh ${VM_USER}@${worker_ip}'" >> "/home/${LOCAL_USER}/.bashrc"
    fi
done
