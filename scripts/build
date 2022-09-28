#!/bin/bash

set -e -o pipefail
#trap 'echo "# $BASH_COMMAND"' DEBUG

REPOROOT="$(git rev-parse --show-toplevel)"
DEMONAME="$(basename "$(pwd)")"
DEMOROOT="${REPOROOT}/${DEMONAME}"

title() {
    echo -e "\E[34m# $1\E[00m";
}

load_blueprint() {
    local name=$1
    local file=$2

    sudo composer-cli blueprints delete "${name}" 2>/dev/null || true
    sudo composer-cli blueprints push "${DEMOROOT}/blueprints/${file}"
    sudo composer-cli blueprints depsolve "${name}"
}

waitfor_image() {
    local uuid=$1

    status=$(sudo composer-cli compose status | grep "${uuid}" | awk '{print $2}')
    while [ "${status}" !=  FINISHED ]; do
        sleep 10
        status=$(sudo composer-cli compose status | grep "${uuid}" | awk '{print $2}')
        echo "$(date +'%Y-%m-%d %H:%M:%S')" "${status}"
        if [ "${status}" == "FAILED" ]
        then
            echo "Blueprint build has failed. For more info, download logs from composer."
            exit 1
        fi
    done
}

download_image() {
    local uuid=$1

    sudo composer-cli compose logs "${uuid}"
    sudo composer-cli compose metadata "${uuid}"
    sudo composer-cli compose image "${uuid}"
}

build_image() {
    local blueprint_file=$1
    local blueprint=$2
    local version=$3
    local image_type=$4
    local parent_blueprint=$5
    local parent_version=$6

    title "Loading ${blueprint} blueprint v${version}"
    load_blueprint "${blueprint}" "${blueprint_file}"

    if [ -n "$parent_version" ]; then
        title "Serving ${parent_blueprint} v${parent_version} container locally"
        sudo podman rm -f "${parent_blueprint}-server" 2>/dev/null || true
        sudo podman rmi -f "localhost/${parent_blueprint}:${parent_version}" 2>/dev/null || true
        imageid=$(cat "./${parent_blueprint}-${parent_version}-container.tar" | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
        sudo podman tag "${imageid}" "localhost/${parent_blueprint}:${parent_version}"
        sudo podman run -d --name="${parent_blueprint}-server" -p 8080:8080 "localhost/${parent_blueprint}:${parent_version}"

        title "Building ${image_type} for ${blueprint} v${version}, parent ${parent_blueprint} v${parent_version}"
        buildid=$(sudo composer-cli compose start-ostree --ref "rhel/8/$(uname -i)/edge" --url http://localhost:8080/repo/ "${blueprint}" "${image_type}" | awk '{print $2}')
    else
        title "Building ${image_type} for ${blueprint} v${version}"
        buildid=$(sudo composer-cli compose start-ostree --ref "rhel/8/$(uname -i)/edge" "${blueprint}" "${image_type}" | awk '{print $2}')
    fi

    waitfor_image "${buildid}"
    download_image "${buildid}"
    sudo chown "$(whoami)." "${buildid}"*.{tar,iso} 2>/dev/null || true
    rename "${buildid}" "${blueprint}-${version}" "${buildid}"*.{tar,iso} 2>/dev/null || true
}


mkdir -p "${DEMOROOT}/builds"
pushd "${DEMOROOT}/builds" &>/dev/null

title "Adding extra RPM repos to host"
mkdir -p /etc/osbuild-composer/repositories/
sudo cp "${REPOROOT}"/_lib/sources/rhel-8*.json /etc/osbuild-composer/repositories/
sudo systemctl restart osbuild-composer.service

for source in "${DEMOROOT}"/sources/*.toml; do
    id="$(grep -Po '^\s?id\s?=\s?"\K[^"]+' "${source}" | head -n 1)"
    title "Adding source '${id}' to builder"
    sudo composer-cli sources delete "${id}" 2>/dev/null || true
    sudo composer-cli sources add "${source}"
done

# Build images from blueprints in alphabetical order of file names.
# Assumes files are named following the pattern "${SOME_NAME}_v${SOME_VERSION}.toml".
# Assumes blueprint N is the parent of blueprint N+1.
parent_version=""
for blueprint in "${DEMOROOT}"/blueprints/*.toml; do
    filename="$(basename "${blueprint}")"
    if [ "${filename}" == installer.toml ]; then continue; fi

    version="$(echo "${filename}" | grep -Po '_v\K(.*)(?=\.toml)')"
    if [ ! -f "${DEMOROOT}/builds/${DEMONAME}-${version}-container.tar" ]; then
        if [ -z "${parent_version}" ]; then
            build_image "${filename}" "${DEMONAME}" "${version}" edge-container
        else
            build_image "${filename}" "${DEMONAME}" "${version}" edge-container "${DEMONAME}" "${parent_version}"
        fi
    else
        title "Skipping build of ${DEMONAME} v${version}"
    fi
    parent_version="${version}"
done

title "Removing extra RPM repos from host" # builder trips on it
sudo rm -f /etc/osbuild-composer/repositories/rhel-8*.json
sudo systemctl restart osbuild-composer.service

# Build the installer ISO if it doesn't exist yet
if [ ! -f "${DEMOROOT}/builds/installer-0.0.0-installer.iso" ]; then
    build_image installer.toml "installer" 0.0.0 edge-installer "${DEMONAME}" 0.0.1
else
    title "Skipping build of installer"
fi

# Embed the kickstart into the installer ISO if there's no ISO containing it yet
if [ ! -f "${DEMOROOT}/builds/installer.$(uname -i).iso" ]; then
    title "Embedding kickstart"
    cp "${DEMOROOT}/blueprints/kickstart.ks" "${DEMOROOT}/builds/kickstart.ks"
    sudo podman run --rm --privileged -ti -v "${DEMOROOT}/builds":/data -v /dev:/dev fedora /bin/bash -c \
        "dnf -y install lorax; cd /data; mkksiso kickstart.ks installer-0.0.0-installer.iso ${DEMONAME}-installer.$(uname -i).iso; exit"
    sudo chown "$(whoami)." "${DEMOROOT}/builds/${DEMONAME}-installer.$(uname -i).iso"
else
    title "Skipping embedding of kickstart"
fi

title "Cleaning up local ostree container serving"
sudo podman rm -f "${DEMONAME}-server" 2>/dev/null || true

title "Done"
popd &>/dev/null
