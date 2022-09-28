#!/bin/bash

if [ -z "${GITOPS_REPO}" -o -z "${UPGRADE_SERVER_IP}" ]; then
    echo "Please set GITOPS_REPO and UPGRADE_SERVER_IP" 1>&2
    exit 1
fi

sed -i "s|https://github.com/redhat-et/microshift-config|${GITOPS_REPO}|" ./blueprints/kickstart.ks
sed -i "s|http://192.168.178.105:8080/repo/|http://${UPGRADE_SERVER_IP}:8080/repo/|" ./blueprints/kickstart.ks
