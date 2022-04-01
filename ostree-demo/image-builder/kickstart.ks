lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
#text
network --bootproto=dhcp --device=link --activate --onboot=on

ostreesetup --nogpg --osname=rhel --remote=edge --url=file:///run/install/repo/ostree/repo --ref=rhel/8/x86_64/edge


%post --log=/var/log/anaconda/post-install.log --erroronfail

#echo -e 'url=http://192.168.178.105:8080/repo/' >> /etc/ostree/remotes.d/edge.conf
#echo -e 'https://github.com/redhat-et/microshift-config?ref=${uuid}' > /etc/transmission-url

useradd -m -d /home/redhat -p \$5\$XDVQ6DxT8S5YWLV7\$8f2om5JfjK56v9ofUkUAwZXTxJl3Sqnc9yPnza4xoJ0 -G wheel redhat
mkdir -p /home/redhat/.ssh
chmod 755 /home/redhat/.ssh
tee /home/redhat/.ssh/authorized_keys > /dev/null << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCsvjLuR4gPLpMlqR8qiepWY+fDYrlPoEVM1FMKayCtHHYC2EPU9H1pkVk7fTSeTVOA2bYaEvYoyBXv+qSLq0qGzrjCM8FpyU5Dhr1kZGw1AmgSlQIqAuknRRjEbGvBLIr6GY3nOOf5knDLaJWqYvmo6Fu2M/k5jHjBmcUlWbTQpdLWaosiRPeE/s7jrzm971B/HqT/1UscDErCiJW3o20nDfl4kfORHC9G8d1QGEap4uM+gtLSayVtOa+Mhyaen8/ixBZILq1XeKuhKIKAbh/ahHJ8DWY1d35cyZzAq5FBKJqAsYNT16/ccIfmNo2Sh+R0mxnkVfxp4c8lL/xjKD5kkZlpghNB0wXgYscSw+gRz3DqVzeHuFARwaehVq5PApQQma+nuBiAywpnpKIp8LflXKYGbRIo7rska3yB4Qsz2812haSumuSpVq/uoeZdymXYojT/59YgZEKtScIDQBADoo+/jZY8eek6M/M3QHm3LFpTZVYpdADfDhf32jDJ+dU= edge@redhat.com
EOF
echo -e 'redhat\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# Enable cockpit:
systemctl enable cockpit.socket
firewall-offline-cmd --add-service=cockpit

# Open microshift ports:
firewall-offline-cmd --zone=public --add-port=80/tcp
firewall-offline-cmd --zone=public --add-port=443/tcp
firewall-offline-cmd --zone=public --add-port=6443/tcp
firewall-offline-cmd --zone=public --add-port=5353/udp

# Configure kubeconfig for redhat user:
mkdir -p /home/redhat/.kube
cat /var/lib/microshift/resources/kubeadmin/kubeconfig > /home/redhat/.kube/config

%end
