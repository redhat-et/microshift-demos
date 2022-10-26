#!/bin/bash

set -e -o pipefail

REPOROOT="$(git rev-parse --show-toplevel)"
DEMOROOT="${REPOROOT}/demos/ibaas-demo"
RHUSER=$1
PASSWD=$2
BUCKET_NAME=$3
PULL_SECRET=$4

title() {
    echo -e "\E[34m\n# $1\E[00m";
}

function create_iso {
    title "Creating the edge-installer ISO using the Red Hat hosted Image Builder service"
    sleep 10
    ID=$(curl -H "Content-Type: application/json" -X POST -u "$RHUSER":"$PASSWD" -d@data-edge-installer.json https://console.redhat.com/api/image-builder/v1/compose | jq -r .id)
    echo $ID > edge-installer-iso-id
}

# Usage function to explain arguments required for this script
function usage() {
    echo "Usage: $(basename $0) <user> <password> <bucket_name> <pull_secret>"
    echo "<user>: User name of your Red Hat account"
    echo "<password>: Password of your Red Hat account"
    echo "<bucket-name>: Name of the S3 bucket to host the RPMs/ostree-commit"
    echo "<pull-secret>: Path to the pull secret file"
    exit 1
}

# Check if the required arguments are provided
if [[ -z "${RHUSER}" || -z "${PASSWD}" || -z "${BUCKET_NAME}" ]]; then
    usage
fi

title "Building MicroShift RPMs from the latest commit and creating a repo"
${REPOROOT}/scripts/build-latest-rpms

title "Preparing S3 bucket to host the RPMs/ostree-commit"
${REPOROOT}/scripts/prepare-aws-bucket "${BUCKET_NAME}"

# Replace placeholders in data-ostree.json
cp data-ostree.json.template data-ostree.json
sed -i "s|BUCKET_NAME|${BUCKET_NAME}|g" data-ostree.json
REGION=$(aws configure get region)
sed -i "s|REGION|${REGION}|g" data-ostree.json

title "Creating the ostree-commit using the Red Hat hosted Image Builder service"
ID=$(curl -H "Content-Type: application/json" -X POST -u "$RHUSER":"$PASSWD" -d@data-ostree.json https://console.redhat.com/api/image-builder/v1/compose | jq -r .id)
echo $ID > ostree-commit-id

# Wait for the ostree-commit to be ready
while true; do
        STATUS=$(curl -u "$RHUSER":"$PASSWD" https://console.redhat.com/api/image-builder/v1/composes/"$ID" | jq -r '.image_status.status')
        case $STATUS in
            "success")
                echo "Creation of ostree-commit successful"
                break
                ;;
            "failure")
                echo "Building the ostree-commit failed"
                exit 1
                ;;
            *)
                echo "Status: $STATUS Waiting for image build to complete"
                sleep 10
                ;;
        esac
    done

# Download the ostree-commit
title "Downloading the ostree-commit"
IMAGE=$(curl -u "$RHUSER":"$PASSWD" https://console.redhat.com/api/image-builder/v1/composes/"$ID" | jq -r '.image_status.upload_status.options.url')
rm -rf ostree-commit.tar ostree-commit
curl -o ostree-commit.tar "$IMAGE"

# Extract the ostree-commit into a directory
title "Extracting the ostree-commit"
mkdir -p ostree-commit
tar -xf ostree-commit.tar -C ostree-commit

# Check that the ostree-commit contains the reference file
if [[ ! -f ostree-commit/repo/refs/heads/rhel/8/x86_64/edge ]]; then
    echo "The ostree-commit does not contain the reference file."
    echo "Please, try to build the ostree-commit again, or just run this script again."
    exit 1
fi

# Sync ostree-commit to S3 bucket with public ACL
title "Syncing ostree-commit to S3 bucket"
aws s3 sync ostree-commit/ "s3://${BUCKET_NAME}" --acl public-read
sleep 10

# Replace placeholders in data-edge-installer.json
cp data-edge-installer.json.template data-edge-installer.json
sed -i "s|BUCKET_NAME|${BUCKET_NAME}|g" data-edge-installer.json
sed -i "s|REGION|${REGION}|g" data-edge-installer.json

# Create the edge-installer ISO using the Red Hat hosted Image Builder service
create_iso

# Wait for the edge-installer ISO to be ready
RETRIES=20
while true; do
    ID=$(cat edge-installer-iso-id)
    STATUS=$(curl -u "$RHUSER":"$PASSWD" https://console.redhat.com/api/image-builder/v1/composes/"$ID" | jq -r '.image_status.status')
    case $STATUS in
        "success")
            echo "Creation of edge-installer ISO successful"
            break
            ;;
        "failure")
            echo "Building the edge-installer ISO failed. Retrying..."
            RETRIES=$((RETRIES-1))
            echo $RETRIES
            if [ $RETRIES -eq 0 ]; then
                echo "Retries exceeded the maximum number of attemps. Exiting..."
                exit 1
            fi
            create_iso
            ;;
        *)
            echo "Status: $STATUS Waiting for image build to complete"
            sleep 10
            ;;
    esac
done

# Download the edge-installer ISO
title "Downloading the edge-installer ISO"
ID=$(cat edge-installer-iso-id)
IMAGE=$(curl -u "$RHUSER":"$PASSWD" https://console.redhat.com/api/image-builder/v1/composes/"$ID" | jq -r '.image_status.upload_status.options.url')
rm -rf edge-installer.iso
curl -o edge-installer.iso "$IMAGE"

# Read pull secret file content
PULL_SECRET_CONTENT=$(cat $PULL_SECRET)

# Replace placeholders in kickstart.ks
cp kickstart.ks.template kickstart.ks
sed -i "s|BUCKET_NAME|${BUCKET_NAME}|g" kickstart.ks
sed -i "s|REGION|${REGION}|g" kickstart.ks
sed -i "s|PULL_SECRET_CONTENT|${PULL_SECRET_CONTENT}|g" kickstart.ks

# Embed specific kickstart file to configure the edge-installer ISO for MicroShift
title "Embedding kickstart file to configure the edge-installer ISO for MicroShift"
mkdir -p ${REPOROOT}/builds/iso
sudo mkksiso kickstart.ks edge-installer.iso ${REPOROOT}/builds/iso/microshift-edge-installer.iso

title "MicroShift ISO is ready at ${REPOROOT}/builds/iso/microshift-edge-installer.iso"
