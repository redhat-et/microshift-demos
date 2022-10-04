# MicroShift Demos

This repo contains demos of various [MicroShift](https://github.com/openshift/microshift) features.

* [ostree-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/ostree-demo): Start here to become familiar with `rpm-ostree` basics (image building, updates&rollbacks, etc.) and "upgrading into MicroShift".
* [e2e-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/e2e-demo): Demonstrates the end-to-end process from device provisioning to management via GitOps and ACM.

## Building demo images on a RHEL machine

Unless otherwise noted, the demos require you to build a couple of artefacts such as `rpm-ostree` container and ISO installer images. The build process is described below.

Start from a RHEL 8.6 or higher machine (virtual or bare metal) registered via `subscription-manager` and attached to a subscription that includes the OpenShift Container Platform repos. You can add a trial evaluation for OCP at [Red Hat Customer Portal - Product Downloads](https://access.redhat.com/downloads). Running `sudo subscription-manager repos --list-enabled | grep ID` should return something similar to:

    Repo ID:   rhel-8-for-x86_64-appstream-rpms
    Repo ID:   rhel-8-for-x86_64-baseos-rpms
    Repo ID:   ansible-2.9-for-rhel-8-x86_64-rpms
    Repo ID:   rhocp-4.11-for-rhel-8-x86_64-rpms
    Repo ID:   fast-datapath-for-rhel-8-x86_64-rpms

Install git if not yet installed and clone the demo repo:

    git clone https://github.com/redhat-et/microshift-demos.git
    cd microshift-demos

Install ImageBuilder and other build dependencies:

    ./scripts/configure-builder

Until MicroShift RPMs are available via the Red Hat CDN, get them according to the [MicroShift project docs](https://github.com/openshift/microshift/blob/main/docs/rpm_packages.md) and place somewhere on disk, then run

    ./scripts/mirror-repos $PATH_TO_MICROSHIFT_RPMS

Build the artefacts for a given demo by running

    ./scripts/build $DEMONAME

whereby `$DEMONAME` is one of the demos in the list above, e.g. `ostree-demo`.

Once the build completes, you should find the demo's artefacts in `builds/$DEMONAME`, e.g. for the `ostree-demo` this will be

    ostree-demo-0.0.1-container.tar
    ostree-demo-0.0.1-metadata.tar
    ostree-demo-0.0.1-logs.tar
    ostree-demo-0.0.2-container.tar
    ...
    ostree-demo-installer.x86_64.iso
