#!/bin/bash

set -e -o pipefail

DEMOROOT=$(git rev-parse --show-toplevel)/e2e-demo

title() {
    echo -e "\E[34m\n# $1\E[00m";
}

load_blueprint() {
    sudo composer-cli blueprints delete $1 2>/dev/null || true
    sudo composer-cli blueprints push ${DEMOROOT}/image-builder/$1.toml
    sudo composer-cli blueprints depsolve $1
}  

waitfor_image() {
    STATUS=$(sudo composer-cli compose status | grep $1 | awk '{print $2}')
    while [ ${STATUS} !=  FINISHED ]; do
        sleep 10
        STATUS=$(sudo composer-cli compose status | grep $1 | awk '{print $2}')
        echo $(date +'%Y-%m-%d %H:%M:%S') ${STATUS}
    done
}

download_image() {
    sudo composer-cli compose logs $1
    sudo composer-cli compose metadata $1
    sudo composer-cli compose image $1
}


mkdir -p ${DEMOROOT}/builds
pushd ${DEMOROOT}/builds &>/dev/null

title "Adding RHOCP and Ansible repos to builder"
sudo cp ${DEMOROOT}/image-builder/rhel-8.json /etc/osbuild-composer/repositories/
sudo systemctl restart osbuild-composer.service

title "Loading r4e-microshift blueprint"
load_blueprint r4e-microshift

title "Building r4e-microshift ostree container image"
UUID=$(sudo composer-cli compose start-ostree --ref rhel/8/$(uname -i)/edge r4e-microshift rhel-edge-container | awk '{print $2}')
waitfor_image ${UUID}
download_image ${UUID}

title "Serving r4e-microshift ostree container locally"
IMAGEID=$(cat ./${UUID}-rhel84-container.tar | sudo podman load | grep -o -P '(?<=@)[a-z0-9]*')
sudo podman tag ${IMAGEID} localhost/rhel-edge-container
sudo podman rm -f rhel-edge-container 2>/dev/null || true
sudo podman run -d --name=rhel-edge-container -p 8080:80 localhost/rhel-edge-container

title "Removing RHOCP and Ansible repos from builder" # builder trips on it
sudo rm /etc/osbuild-composer/repositories/rhel-8.json
sudo systemctl restart osbuild-composer.service

title "Loading installer blueprint"
load_blueprint installer

title "Building installer ISO"
UUID=$(sudo composer-cli compose start-ostree --ref rhel/8/$(uname -i)/edge --url http://localhost:8080/repo/ installer rhel-edge-installer | awk '{print $2}')
waitfor_image ${UUID}
download_image ${UUID}
cp -f ${UUID}-rhel84-boot.iso r4e-microshift-installer.iso

title "Cleaning up local ostree container serving"
sudo podman rm -f rhel-edge-container 2>/dev/null || true
sudo podman rmi -f ${IMAGEID} 2>/dev/null || true

popd &>/dev/null
