#!/bin/bash
set -ue

VM_NAME=${1:?}
IMG=${2:-"focal-server-cloudimg-amd64-disk-kvm.img"}
: "${FORCE:="no"}"
: "${DEBUG:="true"}"
: "${DISK_SIZE:="12G"}"
: "${BRIDGE:="default"}"
: "${LOCAL_USER:="kubeops"}"
: "${VM_PWD:="ops"}"

: "${VM_IFC:="ens2"}"
: "${VM_IP:="192.168.122.10"}"
: "${VM_GW:="192.168.122.1"}"
: "${VM_DNS:="192.168.122.1"}"

RELEASE="$(echo "$IMG" | cut -d'-' -f1)"
BASE_IMG_DIR="/var/lib/libvirt/images/base"
BASE_IMG_PATH="${BASE_IMG_DIR}/${IMG}"
VM_IMG_DIR="/var/lib/libvirt/images/${VM_NAME}"
VM_IMG_PATH="${VM_IMG_DIR}/root-img.qcow2"

# load other scripts
. logging.sh
. common.sh
read_env ".env"

_check_if_address_used() {
  ping ${VM_IP} -c1 && log_err "Address ${VM_IP} is reachable" && exit 1
  # !TODO check vms
}

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo -E)"
  exit 1
fi

if [ -d "${VM_IMG_DIR}" ] && [ "${FORCE}" != "yes" ]; then
  log_warn "VM image path (${VM_IMG_PATH}) already exist, exiting..."
  exit 1
fi

if [ -f "${BASE_IMG_PATH}" ]; then
  log_warn "Base image (${BASE_IMG_PATH}) already exists"
else
  mkdir -p ${BASE_IMG_DIR} || true
  echo "Downloading ${IMG} to ${BASE_IMG_PATH}..."
  curl "https://cloud-images.ubuntu.com/${RELEASE}/current/${IMG}" -o "${BASE_IMG_PATH}"  # !TODO check if file is not corrupted
fi
# check base image
qemu-img check ${BASE_IMG_PATH}

# install required packages
# apt install whois

# create vm disk
mkdir -p ${VM_IMG_DIR} || true
qemu-img create -f qcow2 -F qcow2 -b ${BASE_IMG_PATH} ${VM_IMG_PATH} ${DISK_SIZE}
is_debug && qemu-img info ${VM_IMG_PATH}
# qemu-img resize \
#   ${VM_IMG_PATH} \
#   ${DISK_SIZE}

USERNAME="ops"
PASSWORD="$(mkpasswd --method=SHA-512 --rounds=4096 ${VM_PWD})"
ssh_pub_key=$(cat /home/${LOCAL_USER}/.ssh/id_rsa.pub)
echo "#cloud-config
users:
  - default
  - name: ${USERNAME}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    passwd: ${PASSWORD}
    ssh_authorized_keys:
      - ${ssh_pub_key}
chpasswd:
  list: |
    root:root
  expire: false

hostname: ${VM_NAME}
# configure sshd to allow users logging in using password
# rather than just keys
ssh_pwauth: True
final_message: "Up after \$UPTIME"
" | tee ${VM_IMG_DIR}/user-data

echo "version: 2
ethernets:
  ${VM_IFC}:
    dhcp4: false
    addresses: [ ${VM_IP}/24 ]
    gateway4: ${VM_GW}
    nameservers:
      addresses: [ ${VM_DNS} ]
" | tee ${VM_IMG_DIR}/network-data

echo "Creating cloud iso"
cloud-localds -v --network-config=${VM_IMG_DIR}/network-data ${VM_IMG_DIR}/cloud-init.iso ${VM_IMG_DIR}/user-data
# cloud-localds -v ${VM_IMG_DIR}/cloud-init.iso ${VM_IMG_DIR}/userdata.yaml
# touch ${VM_IMG_DIR}/meta-data
# genisoimage -output ${VM_IMG_DIR}/cloud-init.iso -volid cidata -joliet -rock ${VM_IMG_DIR}/user-data ${VM_IMG_DIR}/meta-data

echo "Creating VM"
virt-install \
  --name "${VM_NAME}" \
  --memory 2048 \
  --vcpu 2 \
  --disk "${VM_IMG_DIR}/root-img.qcow2,device=disk,bus=virtio" \
  --disk "${VM_IMG_DIR}/cloud-init.iso,device=cdrom" \
  --os-type linux \
  --virt-type kvm \
  --noautoconsole \
  --graphics none \
  --network network=${BRIDGE},model=virtio \
  --import
  # --cloud-init user-data=${VM_IMG_DIR}/userdata.yaml \

virsh autostart "${VM_NAME}"
