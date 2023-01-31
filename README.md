# MicroShift Demos

This repo contains demos of various [MicroShift](https://github.com/openshift/microshift) features.

* [hello-microshift-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/hello-microshift-demo): Demonstrates a minimal RHEL for Edge with MicroShift and deploying a "Hello, MicroShift!" app on it.
* [ostree-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/ostree-demo): Become familiar with `rpm-ostree` basics (image building, updates&rollbacks, etc.) and "upgrading into MicroShift".
* [e2e-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/e2e-demo): (outdated!) Demonstrates the end-to-end process from device provisioning to management via GitOps and ACM.
* [ibaas-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/ibaas-demo): Build a RHEL for Edge ISO containing MicroShift and its dependencies in a completely automated manner using Red Hat's Hosted Image Builder service from `console.redhat.com`.

## Building demo images on a RHEL machine

Unless otherwise noted, the demos require you to build a couple of artefacts such as `rpm-ostree` container and ISO installer images. The build process is described below.

Start from a RHEL 8.7 or higher machine (virtual or bare metal) registered via `subscription-manager` and attached to a subscription that includes the OpenShift Container Platform repos. You can add a trial evaluation for OCP at [Red Hat Customer Portal - Product Downloads](https://access.redhat.com/downloads).

Install git if not yet installed and clone the demo repo:

    git clone https://github.com/redhat-et/microshift-demos.git
    cd microshift-demos

Set up Image Builder and other build dependencies:

    ./scripts/configure-builder

Mirror MicroShift and its dependencies into a local repo to accelerate the image build process.

    ./scripts/mirror-repos

Download the OpenShift pull secret from https://console.redhat.com/openshift/downloads#tool-pull-secret and copy it to `$HOME/.pull-secret.json`.

Build the artefacts for a given demo by running

    ./scripts/build $DEMONAME

whereby `$DEMONAME` is one of the demos in the list above, e.g. `ostree-demo`.

Once the build completes, you should find the demo's artefacts in `builds/$DEMONAME`, e.g. for the `ostree-demo` this will be

    id_demo
    id_demo.pub
    ostree-demo-0.0.1-container.tar
    ostree-demo-0.0.1-metadata.tar
    ostree-demo-0.0.1-logs.tar
    ostree-demo-0.0.2-container.tar
    ...
    ostree-demo-installer.x86_64.iso
    password

After deploying a machine with the installer, you should be able to log into it using the user `microshift` and the password in `builds/$DEMONAME/password` or via `ssh` with

    ssh -o "IdentitiesOnly=yes" -i builds/$DEMONAME/id_demo microshift@$MACHINE_IP

## Building demo images with pre-release versions of MicroShift

By default, the `mirror-repos` script will mirror the latest MicroShift version from the official 4.12 release repos.

To mirror the developer preview repos instead (may not always work), use:

    MICROSHIFT_DEV_PREVIEW=true MICROSHIFT_VERSION=4.13 MICROSHIFT_DEPS_VERSION=4.12 ./scripts/mirror-repos

To test the latest MicroShift version built from source instead (may not always work), use:

    ./scripts/build-latest-rpms
    MICROSHIFT_DEV_PREVIEW=true MICROSHIFT_VERSION=4.13 MICROSHIFT_DEPS_VERSION=4.12 ./scripts/mirror-repos
