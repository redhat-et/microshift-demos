#!/bin/bash

set -e -o pipefail

DEMOROOT=$(git rev-parse --show-toplevel)/e2e-demo

sudo rm -f ${DEMOROOT}/builds/*

for uuid in $(sudo composer-cli compose list | awk '{print $1}'); do
    echo "Deleting compose ${uuid}"
    sudo composer-cli compose cancel ${uuid} || true
    sudo composer-cli compose delete ${uuid} || true
done
