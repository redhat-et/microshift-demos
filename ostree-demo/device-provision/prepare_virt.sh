#!/bin/bash

set -exo pipefail

sudo dnf module install -y virt
sudo dnf install -y virt-install virt-viewer

sudo groupadd --system libvirt
sudo usermod -a -G libvirt $(whoami)
sudo sed -i '/unix_sock_group/s/^#//g' /etc/libvirt/libvirtd.conf

sudo systemctl restart libvirtd
sudo virt-host-validate

sudo firewall-cmd --add-port=5900-5910/tcp --permanent
sudo firewall-cmd --reload

# sudo ip link add br0 type bridge

# fzdarsky@lab-05 network-scripts]$ cat ifcfg-eno1 
# TYPE=Ethernet
# PROXY_METHOD=none
# BROWSER_ONLY=no
# BOOTPROTO=dhcp
# DEFROUTE=yes
# IPV4_FAILURE_FATAL=no
# IPV6INIT=yes
# IPV6_AUTOCONF=yes
# IPV6_DEFROUTE=yes
# IPV6_FAILURE_FATAL=no
# NAME=eno1
# UUID=5d717232-4a4c-41b3-9960-c9a843b0e315
# DEVICE=eno1
# ONBOOT=yes
# IPV6_PRIVACY=no

# [fzdarsky@lab-05 network-scripts]$ cat ifcfg-eno1 
# TYPE=Ethernet
# BOOTPROTO=none
# NAME=eno1
# UUID=5d717232-4a4c-41b3-9960-c9a843b0e315
# DEVICE=eno1
# ONBOOT=yes
# BRIDGE=br0
# DELAY=0
# NM_CONTROLLED=0

# [fzdarsky@lab-05 network-scripts]$ cat ifcfg-br0 
# DEVICE=br0
# TYPE=Bridge
# BOOTPROTO=none
# IPADDR=192.168.178.105
# GATEWAY=192.168.178.1
# NETMASK=255.255.255.0
# ONBOOT=yes
# DELAY=0
# NM_CONTROLLED=0
