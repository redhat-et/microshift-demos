#!/bin/bash

set -exo pipefail

REPOROOT=$(git rev-parse --show-toplevel)

sudo composer-cli blueprints delete r4e-microshift 2>/dev/null || true
sudo composer-cli blueprints push ./r4e-microshift.toml
sudo composer-cli blueprints depsolve r4e-microshift

UUID=$(sudo composer-cli compose start r4e-microshift rhel-edge-commit | awk '{print $2}')

STATUS=$(sudo composer-cli compose status | grep ${UUID} | awk '{print $2}')
while [ ${STATUS} !=  FINISHED ]; do
    sleep 60
    STATUS=$(sudo composer-cli compose status | grep ${UUID} | awk '{print $2}')
    echo $(date --rfc-3339=seconds -u) ${STATUS}
done

mkdir -p ${REPOROOT}/builds
pushd ${REPOROOT}/builds &>/dev/null
echo ${UUID} > uuid.txt
sudo composer-cli compose logs ${UUID}
sudo composer-cli compose image ${UUID}
sudo composer-cli compose metadata ${UUID}
popd &>/dev/null
