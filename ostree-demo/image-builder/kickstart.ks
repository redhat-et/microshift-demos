lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=dhcp --device=link --activate --onboot=on --hostname=edge.local

ostreesetup --nogpg --osname=rhel --remote=edge --url=file:///run/install/repo/ostree/repo --ref=rhel/8/x86_64/edge


%post --log=/var/log/anaconda/post-install.log --erroronfail

# Set repo URL for ostree updates
echo -e 'url=http://10.0.14.232:8080/repo/' >> /etc/ostree/remotes.d/edge.conf

# Add a user 'microshift' and make it passwordless sudoer
useradd -m -d /home/microshift -p \$5\$XDVQ6DxT8S5YWLV7\$8f2om5JfjK56v9ofUkUAwZXTxJl3Sqnc9yPnza4xoJ0 -G wheel microshift
mkdir -p /home/microshift/.ssh
chmod 755 /home/microshift/.ssh
tee /home/microshift/.ssh/authorized_keys > /dev/null << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxnQB1tTWJBbt4sGwV9AEfz+Y8FKRvrOaeP3+1O3C0VhBjgsYtroH8g7oJWBHS+mXYjY7SpmV5ML5zw6rT4DjL2XKgxZFglWoF9aKs4Hm4hqzx1MvtIlGozqh7tPxDFiyi/u4yNZhnF46lS9OzFp82g/ejRinuG7TTq5WNFSTpElDMpXOqzFx0l5IBNjsDLL2Cj7gHEuCVBP9bEXOEqZkNDFDqqZRrFlnosdikoqaCVzPCfXf1obWAuLLGb2NjUd/xuRl/hTjMiuXxqbmkRzEkjwnoVQ/bUKmfZPEcLPBQ+ttugDq+fbeTNdJi5ucuqTigiFNZJt26yMK7Ic2YDlycOhZsiSwRJ1PNCFUFUGhSyt5GnudhxJTVlOmKPWgzCoCgLypVDkledkSXSH+Y+q+4yXZDh1J7h0al6DBkH/XqxmSQU7jbCGWNhlSMYgeuqUhvySmv1o5EvWJLMxQXCp5gxcgLeM4LWkIpqrwnGv66Nw2JQ4GPGkemhdnf77xuWA5wgml5jAOtrTiLYKi71Tb8bRrOxIXqRMIXcU2I9FYZ1/db/IVoYYQRV9ZHvVMrxKeX0sL3d6wH9E39z9fTdNf6HOXucIJ7dXDkhC8GktTlPZ5f1YbfcB4JQTP7hHxWWIA9ouPb+tU35myV+IykV3ll7OASh166ZuKzWPAo6NWGZQ== edge@lab
EOF
echo -e 'microshift\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# set up kubeconfig
mkdir -p /home/microshift/.kube
chmod 755 /home/microshift/.kube
chown microshift. /home/microshift/.kube
echo "sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig > .kube/config 2> /dev/null" >> /home/microshift/.bashrc

# configure firewall rules
firewall-offline-cmd --zone=trusted --add-source=10.42.0.0/16
firewall-offline-cmd --zone=public --add-port=80/tcp
echo "127.0.0.1 hello-world.local" >> /etc/hosts

%end
