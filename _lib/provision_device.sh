#!/bin/bash

set -e -o pipefail

DEMOROOT=$(git rev-parse --show-toplevel)/ostree-demo

# sudo virsh net-define ${DEMOROOT}/device-provision/macvtap-network.xml || true
# sudo virsh net-autostart macvtap-net || true
# sudo virsh net-start macvtap-net || true

sudo virt-install \
    --name ostree-demo \
    --vcpus 2 \
    --memory 4096 \
    --disk path=/var/lib/libvirt/images/ostree-demo.qcow2,size=20 \
    --network network=default,model=virtio,mac=52:54:00:00:00:01 \
    --os-type linux \
    --os-variant rhel8.5 \
    --cdrom /var/lib/libvirt/images/ostree-demo-installer.x86_64.iso
