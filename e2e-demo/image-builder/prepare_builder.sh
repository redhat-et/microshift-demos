#!/bin/bash

set -exo pipefail

# install image builder
sudo dnf install -y git osbuild-composer composer-cli cockpit-composer bash-completion
sudo systemctl enable osbuild-composer.socket --now
sudo systemctl enable cockpit.socket --now
sudo firewall-cmd -q --add-service=cockpit
sudo firewall-cmd -q --add-service=cockpit --permanent

# configure dependencies for MicroShift blueprint
ARCH=$(uname -m)
OCP_VERSION="4.7"
OCP_ENTITLEMENT="$(egrep -e "^\[[a-z0-9._-]+]" /etc/yum.repos.d/redhat.repo -e sslclientcert | sed 'N;s/\n/ /' | grep rhocp-${OCP_VERSION}-for-rhel-8-${ARCH}-rpms | egrep -o '/etc/pki/entitlement/([0-9])+')"
GPG_KEY=$(cat /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release | sed '/^$/d' | sed '/^Version/d' | sed '0,/^pub /d' | sed -z 's/\n/\\n/g')

sudo subscription-manager repos --enable="rhocp-${OCP_VERSION}-for-rhel-8-${ARCH}-rpms"
cat << EOF > rhel-8.json
{
    "${ARCH}": [
        {
            "name": "baseos",
            "baseurl": "https://cdn.redhat.com/content/dist/rhel8/8/${ARCH}/baseos/os",
            "gpgkey": "${GPG_KEY}",
            "rhsm": true,
            "check_gpg": true
        },
        {
            "name": "appstream",
            "baseurl": "https://cdn.redhat.com/content/dist/rhel8/8/${ARCH}/appstream/os",
            "gpgkey": "${GPG_KEY}",
            "rhsm": true,
            "check_gpg": true
        },
        {
            "name": "rhocp",
            "baseurl": "https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.7/os",
            "gpgkey": "${GPG_KEY}",
            "rhsm": true,
            "check_gpg": true
        }
    ]
}
EOF
# "sslverify": true,
# "sslcacert": "/etc/rhsm/ca/redhat-uep.pem",
# "sslclientkey": "${OCP_ENTITLEMENT}-key.pem",
# "sslclientcert": "${OCP_ENTITLEMENT}.pem"

sudo mkdir -p /etc/osbuild-composer/repositories
sudo cp rhel-8.json /etc/osbuild-composer/repositories && rm rhel-8.json
sudo systemctl restart osbuild-worker@.service.d osbuild-worker@1.service osbuild-composer.service
