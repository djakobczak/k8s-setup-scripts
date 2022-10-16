#!/bin/bash
set -ue

# load other scripts
. common.sh
. logging.sh

read_env ".env"

# define vars
: "${ACTION_INSTALL_PREREQS:="no"}"
: "${ACTION_CREATE_VMS="yes"}"
SCRIPT_DIR="/tmp"


# -------------------- FUNCTIONS --------------------
__copy_script() {
    local vm_ip="${1}"
    local script="${2}"
    sshpass -p "${VM_PWD}" scp ${SSH_OPTS} \
      -p "${script}" "${VM_USER}@${vm_ip}":"${SCRIPT_DIR}"
}

__copy_scripts() {
    local vm_ip="${1}"
    scripts=("install_microk8s.sh" "update_etc_hosts.sh")
    for script in "${scripts[@]}"; do
        __copy_script "${vm_ip}" "${script}"
    done
}

__template_scripts() {
    for script in templates/*.tmpl; do
        dst_file=$(basename "${script%.*}")
        bash "${script}" > "${dst_file}"
        chmod +x "${dst_file}"
    done
}

__remote_exec_script() {
  local vm_ip="${1}"
  local script="${2}"
  sshpass -p "${VM_PWD}" \
    ssh ${SSH_OPTS} "${VM_USER}@${vm_ip}" \
    "echo \"${VM_PWD}\" | sudo bash -c ${SCRIPT_DIR}/${script}"
}

__remote_exec_cmd() {
  local vm_ip="${1}"
  local cmd="${2}"
  sshpass -p "${VM_PWD}" \
    ssh ${SSH_OPTS} "${VM_USER}@${vm_ip}" "${cmd}"
}

__get_join_cmd() {
    local master_ip="${1}"
    __remote_exec_cmd "${master_ip}" "microk8s add-node --format short"
}

__wait_for_ssh() {
    local vm_ip="${1}"
    log_info "Waiting for ssh (${VM_USER}@${vm_ip})..."
    until sshpass -p "${VM_PWD}" ssh ${SSH_OPTS} "${VM_USER}@${vm_ip}" exit 2> /dev/null
    do
        log_info "Waiting for ssh (${VM_USER}@${vm_ip})..."
        sleep 5
    done
}

# -------------------- START SCRIPT --------------------
if [ "${ACTION_INSTALL_PREREQS}" == "yes" ]; then
    log_info "Installing prereqs"
    . prereqs.sh
fi

if [ "${ACTION_CREATE_VMS}" == "yes" ]; then
    log_info "Creating cluster VMs"
    VM_IP=${MASTER0_IP} ./create-vm.sh "${MASTER0_NAME}"
    for idx in "${!WORKERS_NAMES[@]}"; do
        VM_IP=${WORKERS_IPS[idx]} ./create-vm.sh "${WORKERS_NAMES[idx]}"
    done
fi

for worker_ip in "${WORKERS_IPS[@]}"; do
    __wait_for_ssh "${worker_ip}"
done
__wait_for_ssh "${MASTER0_IP}"

log_info "Installing cluster"
__template_scripts

__copy_scripts "${MASTER0_IP}"
log_info "Installing ${MASTER0_NAME}"
__remote_exec_script "${MASTER0_IP}" install_microk8s.sh || true
__remote_exec_script "${MASTER0_IP}" update_etc_hosts.sh
__remote_exec_cmd "${MASTER0_IP}" "echo \"alias kubectl='microk8s kubectl'\" >> ~/.bashrc"

for idx in "${!WORKERS_NAMES[@]}"; do
    join_cmd="$(__get_join_cmd "${MASTER0_IP}" | head -1)"
    join_cmd="${join_cmd} --worker"
    log_info "Join command: ${join_cmd}"

    worker_ip="${WORKERS_IPS[idx]}"
    __copy_scripts "${worker_ip}"
    log_info "Installing ${WORKERS_NAMES[idx]}"
    __remote_exec_script "${worker_ip}" install_microk8s.sh || true
    __remote_exec_script "${worker_ip}" update_etc_hosts.sh

    log_info "Joining ${worker_ip}"
    __remote_exec_cmd "${worker_ip}" "${join_cmd}"
done

./set_cluster_ssh.sh
