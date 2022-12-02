# MicroShift Demos

This repo contains demos of various [MicroShift](https://github.com/openshift/microshift) features.

* [hello-microshift-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/hello-microshift-demo): Demonstrates a minimal RHEL for Edge with MicroShift and deploying a "Hello, MicroShift!" app on it.
* [ostree-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/ostree-demo): Become familiar with `rpm-ostree` basics (image building, updates&rollbacks, etc.) and "upgrading into MicroShift".
* [e2e-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/e2e-demo): (outdated!) Demonstrates the end-to-end process from device provisioning to management via GitOps and ACM.
* [ibaas-demo](https://github.com/redhat-et/microshift-demos/tree/main/demos/ibaas-demo): Build a RHEL for Edge ISO containing MicroShift and its dependencies in a completely automated manner using Red Hat's Hosted Image Builder service from `console.redhat.com`.

## Building demo images on a RHEL machine

Unless otherwise noted, the demos require you to build a couple of artefacts such as `rpm-ostree` container and ISO installer images. The build process is described below.

Start from a RHEL 8.7 or higher machine (virtual or bare metal) registered via `subscription-manager` and attached to a subscription that includes the OpenShift Container Platform repos. You can add a trial evaluation for OCP at [Red Hat Customer Portal - Product Downloads](https://access.redhat.com/downloads). Running `sudo subscription-manager repos --list-enabled | grep ID` should return something similar to:

    Repo ID:   rhel-8-for-x86_64-appstream-rpms
    Repo ID:   rhel-8-for-x86_64-baseos-rpms
    Repo ID:   fast-datapath-for-rhel-8-x86_64-rpms
    Repo ID:   rhocp-4.11-for-rhel-8-x86_64-rpms
    Repo ID:   ansible-2.9-for-rhel-8-x86_64-rpms

Install git if not yet installed and clone the demo repo:

    git clone https://github.com/redhat-et/microshift-demos.git
    cd microshift-demos

Install ImageBuilder and other build dependencies:

    ./scripts/configure-builder

Once MicroShift 4.12 is released, you'll find its RPMs in the official repos on the Red Hat CDN. For now, we will need to build the MicroShift RPMs from source.

    ./scripts/build-latest-rpms

Afterwards, the RPMs are available under `./builds/rpms`. Next, we'll mirror these and other dependencies into local repos to accelerate the image build process.

    ./scripts/mirror-repos ./builds/rpms

Download the OpenShift pull secret from https://console.redhat.com/openshift/downloads#tool-pull-secret and copy it to `$HOME/.pull-secret.json`.

Build the artefacts for a given demo by running

    ./scripts/build $DEMONAME

whereby `$DEMONAME` is one of the demos in the list above, e.g. `ostree-demo`.

> :warning: Should you encounter a build error similar to
>
>     ERROR: BlueprintsError: ostree-demo: DNF error occurred: RepoError: There was a problem reading a repository: Failed to download metadata for repo '2c28d9e...' [ansible-local: file:///home/user/path/to/builds/mirror/ansible-local/]: Cannot download repomd.xml: Cannot download repodata/repomd.xml: All mirrors were tried
>
> then the reason is likely that osbuild-composer cannot access the mirror directory (since RHEL 8.7 it runs as non-privileged _osbuild-composer user). You may then need to make your home dir traversable by other users.
>
>     chmod o+x $HOME

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