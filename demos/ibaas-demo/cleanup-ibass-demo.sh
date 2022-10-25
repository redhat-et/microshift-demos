#!/bin/bash

set -e -o pipefail

REPOROOT="$(git rev-parse --show-toplevel)"
DEMOROOT="${REPOROOT}/demos/ibaas-demo"
RPMDIR="${REPOROOT}/builds/rpms"
ISODIR="${REPOROOT}/builds/iso"


title() {
    echo -e "\E[34m\n# $1\E[00m";
}

title "Cleaning up the MicroShift IBaaS demo environment."
echo "This script will not clean any S3 bucket content."

# Delete the ostree-commit
rm -rf ostree-commit.tar ostree-commit-id ostree-commit data-ostree.json
# Delete ISO assets
rm -rf data-edge-installer.json edge-installer-iso-id kickstart.ks
# Delete the RPMs
rm -rf ${RPMDIR}
# Delete ISO
rm -rf edge-installer.iso
rm -rf ${ISODIR}

