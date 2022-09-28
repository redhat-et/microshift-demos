#!/bin/bash

set -e -o pipefail

DEMOROOT=$(git rev-parse --show-toplevel)/ostree-demo

sudo cp ${DEMOROOT}/builds/ostree-demo-installer.x86_64.iso /var/lib/libvirt/images
sudo rm /var/lib/libvirt/images/ostree-demo.qcow2 || true
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/ostree-demo.qcow2 20G
