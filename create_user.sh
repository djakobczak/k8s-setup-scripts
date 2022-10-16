#!/bin/bash
# !TODO add to setup script

sudo useradd -s /bin/bash -m kubeops
sudo passwd kubeops
sudo usermod -a -G kvm kubeops
sudo usermod -a -G libvirt kubeops
sudo usermod -a -G docker kubeops
sudo usermod -a -G sudo kubeops
