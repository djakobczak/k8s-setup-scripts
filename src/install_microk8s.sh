#!/bin/bash
set -u

if command -v microk8s &> /dev/null
then
    echo "microk8s already installed"
    exit 1
fi

snap install microk8s --classic --channel=1.25

# usermod -a -G microk8s "$VM_USER"  # !TODO move to ./templates
# chown -f -R "$VM_USER" ~/.kube

usermod -a -G microk8s ops
chown -f -R ops ~/.kube
microk8s status --wait-ready
microk8s kubectl get nodes
