#!/bin/bash

set -e -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
DEMO_ROOT="${REPO_ROOT}/demos/edge-console-demo"

INPUT_ISO=$1
CREDENTIALS=$2
PULL_SECRET=$3
OUTPUT_ISO=$4
AUTH_KEY=${AUTH_KEY:-~/.ssh/id_rsa.pub}

title() {
    echo -e "\e[1;32m$1\e[0m"
}

check_tool_installed() {
    if ! command -v $1 &> /dev/null
    then
        echo "Please install $1"
        exit
    fi
}

check_sudo_works() {
    if ! sudo -n true 2>/dev/null; then
        echo "Please add yourself to sudoers"
        exit
    fi
}

usage() {
    echo "Usage: $0 <input ISO> <fleet_rhc_credentials> <pull secret> <output ISO>"
    echo " <input ISO> is the iso downloaded from the image builder in console.redhat.com"
    echo " <fleet_rhc_credentials> is a file with the credentials to connect the system to"
    echo "                         hosted fleet manager"
    echo "                         the file must set the following variables:"
    echo "                         RHC_USER + RHC_PASS"
    echo "                         or  RHC_ORGID + RHC_ACTIVATION_KEY"
    echo "                         RHC_FIRSTBOOT=true"
    echo " <pull secret> is the pull secret obtained from  https://console.redhat.com/openshift/downloads#tool-pull-secret"
    echo " <output ISO> is the output ISO with the embedded kickstart"
    exit 1
}

check_tool_installed mkksiso

if [ -z "$INPUT_ISO" ] || [ -z "$CREDENTIALS" ] || [ -z "$PULL_SECRET" ] || [ -z "$OUTPUT_ISO" ]; then
    usage
fi

if [ ! -f "$AUTH_KEY" ]; then
    echo "Please create an ssh key pair and set the AUTH_KEY variable to the public key file"
    echo "this script looks by default for AUTH_KEY defaults to ${AUTH_KEY}"
    exit 1
fi
if [ ! -f "$INPUT_ISO" ]; then
    echo "Input ISO $INPUT_ISO does not exist"
    exit 1
fi

if [ ! -f "$PULL_SECRET" ]; then
    echo "Input pull secret $PULL_SECRET does not exist"
    exit 1
fi

if [ ! -f "$CREDENTIALS" ]; then
    echo "Input credentials $CREDENTIALS does not exist"
    exit 1
fi

# make temporary directory 
TMPDIR=$(mktemp -d)
trap "[[ ! -z "$TMPDIR" ]] && rm -rf ${TMPDIR}" EXIT

title "Creating kickstart file"

cp "${DEMO_ROOT}/demo-kickstart.ks.template" "${TMPDIR}/kickstart.ks"

# Read pull secret file content
PULL_SECRET_CONTENT=$(cat $PULL_SECRET)
SSH_PUBKEY_CONTENT=$(cat $AUTH_KEY)
RHC_CREDS_CONTENT=$(cat $CREDENTIALS | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\$/\\$/g')

echo " - injecting pull secret"
sed -i "s|__PULL_SECRET__|${PULL_SECRET_CONTENT}|g" "${TMPDIR}/kickstart.ks"

echo " - injecting ssh pub key from ${AUTH_KEY}"
sed -i "s|__AUTH_KEYS__|${SSH_PUBKEY_CONTENT}|g" "${TMPDIR}/kickstart.ks"

echo " - injecting rhc credentials from ${CREDENTIALS}"
sed -i "s|__RHC_CREDENTIALS__|${RHC_CREDS_CONTENT}|g" "${TMPDIR}/kickstart.ks"

title "Creating ISO, this will require sudo privileges"

sudo mkksiso "${TMPDIR}/kickstart.ks" "${INPUT_ISO}" "${TMPDIR}/output.iso"
rm -f "${OUTPUT_ISO}" 2>/dev/null || true
mv "${TMPDIR}/output.iso" "${OUTPUT_ISO}"

echo moved "${TMPDIR}/output.iso" to "${OUTPUT_ISO}"
cp "${TMPDIR}/kickstart.ks" "${OUTPUT_ISO}.ks"

title "Done!"