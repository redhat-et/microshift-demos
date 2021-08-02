lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=dhcp --device=link --activate --onboot=on

ostreesetup --nogpg --osname=rhel-edge-microshift --remote=rhel-edge-microshift --url=file:///ostree/repo --ref=rhel/8/x86_64/edge

%post --log=/var/log/anaconda/post-install.log --erroronfail
useradd -m -d /home/redhat -p \$5\$XDVQ6DxT8S5YWLV7\$8f2om5JfjK56v9ofUkUAwZXTxJl3Sqnc9yPnza4xoJ0 -G wheel redhat
echo -e 'redhat\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

echo -e 'https://github.com/fzdarsky/microshift-config?ref=${uuid}' > /etc/transmission-url
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
