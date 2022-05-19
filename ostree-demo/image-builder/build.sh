#!/bin/bash

set -e -o pipefail
#trap 'echo "# $BASH_COMMAND"' DEBUG

DEMONAME=ostree-demo
DEMOROOT=$(git rev-parse --show-toplevel)/${DEMONAME}

title() {
    echo -e "\E[34m\n# $1\E[00m";
}

load_blueprint() {
    local name=$1
    local file=$2

    sudo composer-cli blueprints delete ${name} 2>/dev/null || true
    sudo composer-cli blueprints push "${DEMOROOT}/image-builder/${file}"
    sudo composer-cli blueprints depsolve ${name}
}  

waitfor_image() {
    local uuid=$1

    status=$(sudo composer-cli compose status | grep ${uuid} | awk '{print $2}')
    while [ "${status}" !=  FINISHED ]; do
        sleep 10
        status=$(sudo composer-cli compose status | grep ${uuid} | awk '{print $2}')
        echo $(date +'%Y-%m-%d %H:%M:%S') ${status}
        if [ "${status}" == "FAILED" ]
        then
            echo "Blueprint build has failed. For more info, download logs from composer."
            exit 1
        fi
    done
}

download_image() {
    local uuid=$1

    sudo composer-cli compose logs ${uuid}
    sudo composer-cli compose metadata ${uuid}
    sudo composer-cli compose image ${uuid}
}

build_image() {
    local blueprint_file=$1
    local blueprint=$2
    local version=$3
    local image_type=$4
    local parent_blueprint=$5
    local parent_version=$6

    title "Loading ${blueprint} blueprint v${version}"
    load_blueprint ${blueprint} ${blueprint_file}

    if [ -n "$parent_version" ]; then
        title "Serving ${parent_blueprint} v${parent_version} container locally"
        sudo podman rm -f ${parent_blueprint}-server 2>/dev/null || true
        sudo podman rmi -f localhost/${parent_blueprint}:${parent_version} 2>/dev/null || true
        imageid=$(cat ./${parent_blueprint}-${parent_version}-container.tar | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
        sudo podman tag ${imageid} localhost/${parent_blueprint}:${parent_version}
        sudo podman run -d --name=${parent_blueprint}-server -p 8080:8080 localhost/${parent_blueprint}:${parent_version}

        title "Building ${image_type} for ${blueprint} v${version}, parent ${parent_blueprint} v${parent_version}"
        buildid=$(sudo composer-cli compose start-ostree --ref rhel/8/$(uname -i)/edge --url http://localhost:8080/repo/ ${blueprint} ${image_type} | awk '{print $2}')
    else
        title "Building ${image_type} for ${blueprint} v${version}"
        buildid=$(sudo composer-cli compose start-ostree --ref rhel/8/$(uname -i)/edge ${blueprint} ${image_type} | awk '{print $2}')
    fi

    waitfor_image ${buildid}
    download_image ${buildid}
    rename ${buildid} ${blueprint}-${version} ${buildid}*.{tar,iso} 2>/dev/null || true
}


mkdir -p ${DEMOROOT}/builds
pushd ${DEMOROOT}/builds &>/dev/null


title "Adding RHOCP and Ansible repos to builder"
mkdir -p /etc/osbuild-composer/repositories/
sudo cp ${DEMOROOT}/image-builder/rhel-8.json /etc/osbuild-composer/repositories/
sudo cp ${DEMOROOT}/image-builder/rhel-86.json /etc/osbuild-composer/repositories/
sudo systemctl restart osbuild-composer.service

title "Loading sources for transmission"
sudo composer-cli sources delete transmission 2>/dev/null || true
sudo composer-cli sources add ${DEMOROOT}/image-builder/transmission.toml

title "Loading sources for microshift"
sudo composer-cli sources delete microshift 2>/dev/null || true
sudo composer-cli sources add ${DEMOROOT}/image-builder/microshift.toml
sudo composer-cli sources delete microshift-containers 2>/dev/null || true
sudo composer-cli sources add ${DEMOROOT}/image-builder/microshift-containers.toml
sudo composer-cli sources delete microshift-hello-world 2>/dev/null || true
sudo composer-cli sources add ${DEMOROOT}/image-builder/microshift-hello-world.toml

build_image blueprint_v0.0.1.toml "${DEMONAME}" 0.0.1 edge-container
build_image blueprint_v0.0.2.toml "${DEMONAME}" 0.0.2 edge-container "${DEMONAME}" 0.0.1
build_image blueprint_v0.0.3.toml "${DEMONAME}" 0.0.3 edge-container "${DEMONAME}" 0.0.2

title "Removing RHOCP and Ansible repos from builder" # builder trips on it
sudo rm /etc/osbuild-composer/repositories/rhel-8.json
sudo rm /etc/osbuild-composer/repositories/rhel-86.json
sudo systemctl restart osbuild-composer.service

build_image installer.toml "${DEMONAME}-installer" 0.0.0 edge-installer "${DEMONAME}" 0.0.1

title "Embedding kickstart"
cp "${DEMOROOT}/image-builder/kickstart.ks" "${DEMOROOT}/builds/kickstart.ks"
sudo podman run --rm --privileged -ti -v "${DEMOROOT}/builds":/data -v /dev:/dev fedora /bin/bash -c \
    "dnf -y install lorax; cd /data; mkksiso kickstart.ks ${DEMONAME}-installer-0.0.0-installer.iso ${DEMONAME}-installer.$(uname -i).iso; exit"

title "Cleaning up local ostree container serving"
sudo podman rm -f ${DEMONAME}-server 2>/dev/null || true

sudo chown $(whoami). "${DEMOROOT}/builds/"*

title "Done"
popd &>/dev/null
