lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=dhcp
user --name redhat --groups=wheel --iscrypted --password=$y$j9T$0733AsAQLiXWNSFomZ428/$c9zvx7nJFU24esczY7PxHG6bo71K57TPjEbNskfOBO3
services --enabled=ostree-remount
ostreesetup --nogpg --url=http://192.168.122.1:8080/repo --osname=rhel --remote=edge --ref=rhel/8/x86_64/edge
