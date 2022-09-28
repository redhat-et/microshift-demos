lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=dhcp --device=link --activate --onboot=on

ostreesetup --osname=rhel-edge-microshift --remote=rhel-edge-microshift --url=file:///run/install/repo/ostree/repo --ref=rhel/8/x86_64/edge --nogpg

%post --log=/var/log/anaconda/post-install.log --erroronfail
useradd -m -d /home/redhat -p \$5\$XDVQ6DxT8S5YWLV7\$8f2om5JfjK56v9ofUkUAwZXTxJl3Sqnc9yPnza4xoJ0 -G wheel redhat
mkdir -p /home/redhat/.ssh
chmod 755 /home/redhat/.ssh
tee /home/redhat/.ssh/authorized_keys > /dev/null << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxnQB1tTWJBbt4sGwV9AEfz+Y8FKRvrOaeP3+1O3C0VhBjgsYtroH8g7oJWBHS+mXYjY7SpmV5ML5zw6rT4DjL2XKgxZFglWoF9aKs4Hm4hqzx1MvtIlGozqh7tPxDFiyi/u4yNZhnF46lS9OzFp82g/ejRinuG7TTq5WNFSTpElDMpXOqzFx0l5IBNjsDLL2Cj7gHEuCVBP9bEXOEqZkNDFDqqZRrFlnosdikoqaCVzPCfXf1obWAuLLGb2NjUd/xuRl/hTjMiuXxqbmkRzEkjwnoVQ/bUKmfZPEcLPBQ+ttugDq+fbeTNdJi5ucuqTigiFNZJt26yMK7Ic2YDlycOhZsiSwRJ1PNCFUFUGhSyt5GnudhxJTVlOmKPWgzCoCgLypVDkledkSXSH+Y+q+4yXZDh1J7h0al6DBkH/XqxmSQU7jbCGWNhlSMYgeuqUhvySmv1o5EvWJLMxQXCp5gxcgLeM4LWkIpqrwnGv66Nw2JQ4GPGkemhdnf77xuWA5wgml5jAOtrTiLYKi71Tb8bRrOxIXqRMIXcU2I9FYZ1/db/IVoYYQRV9ZHvVMrxKeX0sL3d6wH9E39z9fTdNf6HOXucIJ7dXDkhC8GktTlPZ5f1YbfcB4JQTP7hHxWWIA9ouPb+tU35myV+IykV3ll7OASh166ZuKzWPAo6NWGZQ== edge@lab
EOF
echo -e 'redhat\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

echo -e 'https://github.com/redhat-et/microshift-config?ref=${insightsid}' > /etc/transmission-url
%end

%post --log=/var/log/anaconda/insights-on-reboot-unit-install.log --interpreter=/usr/bin/bash --erroronfail
INSIGHTS_CLIENT_OVERRIDE_DIR=/etc/systemd/system/insights-client.service.d
INSIGHTS_CLIENT_OVERRIDE_FILE=$INSIGHTS_CLIENT_OVERRIDE_DIR/override.conf

if [ ! -f $INSIGHTS_CLIENT_OVERRIDE_FILE ]; then
    mkdir -p $INSIGHTS_CLIENT_OVERRIDE_DIR
    cat > $INSIGHTS_CLIENT_OVERRIDE_FILE << EOF 
[Unit]
Requisite=greenboot-healthcheck.service
After=network-online.target greenboot-healthcheck.service

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable insights-client.service
fi
%end
