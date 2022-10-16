#!/bin/bash
apt update
apt -y install \
    bridge-utils \
    cpu-checker \
    libvirt-clients \
    libvirt-daemon \
    libvirt-daemon-system \
    qemu \
    qemu-kvm \
    cloud-image-utils \
    virtinst \
    curl \
    sshpass \
    whois
kvm-ok
