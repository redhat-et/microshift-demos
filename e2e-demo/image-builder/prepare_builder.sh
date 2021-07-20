#!/bin/bash

set -exo pipefail

# install image builder
sudo dnf install -y git osbuild-composer composer-cli cockpit-composer bash-completion
sudo systemctl enable osbuild-composer.socket --now
sudo systemctl enable cockpit.socket --now
sudo firewall-cmd -q --add-service=cockpit
sudo firewall-cmd -q --add-service=cockpit --permanent

sudo cp rhel-8.json /usr/share/osbuild-composer/repositories/ && rm rhel-8.json
sudo systemctl restart osbuild-composer.service
