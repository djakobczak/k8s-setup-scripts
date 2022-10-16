#!/bin/bash
VM_NAME="${1:?}"

virsh shutdown ${VM_NAME}
virsh undefine ${VM_NAME}
