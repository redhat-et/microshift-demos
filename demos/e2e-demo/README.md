# MicroShift E2E Provisioning Demo

This demo shows an end-to-end provisioning workflow for MicroShift on a RHEL4Edge device:

* building a RHEL4Edge installer image containing MicroShift's dependencies,
* provisioning and on-boarding a new device into the RHEL4Edge Fleet Manager,
* deploying MicroShift to that device using GitOps and getting the MicroShift cluster registered with Open Cluster Management, and
* deploying a test workload on MicroShift via Open Cluster Management.

## Pre-requisites

Follow the instructions for [building demo images on a RHEL machine](https://github.com/redhat-et/microshift-demos/tree/main/README.md) to build the `e2e-demo` artefacts.

For this demo, you also need a GitHub repo from which you will configure the RHEL edge device running MicroShift via GitOps. Fork the demo's GitOps repo https://github.com/redhat-et/microshift-config into your own org and define the GITOPS_REPO environment variable accordingly:

    export GITOPS_REPO="https://github.com/MY_ORG/microshift-config"

Finally, you need an [Open Cluster Management](https://open-cluster-management.io/) instance accessible by the device you'll provision as well as the `oc` client installed on the machine you'll register the cluster from.

## Provsioning and On-Boarding a Device

Use the installer ISO to provision a physical device or VM (e.g. on libvirt).

When the device boots into the RHEL 4 Edge image for the first time, it'll eventually automatically on-board via [FIDO Device Onboard](https://fidoalliance.org/intro-to-fido-device-onboard/). Until that is implemented, your device needs to be *connected to Red Hat VPN* and you need to perform a few manual steps:

1. Log into the device's console (user: redhat, password: redhat).
2. `curl` and run the `register_device.sh` script from the demo repo:

        curl https://raw.githubusercontent.com/redhat-et/microshift-demos/main/e2e-demo/register_device.sh | sudo sh -

3. When prompted, enter your RHSM credentials.

You should now be able to see your device registered under [https://console.stage.redhat.com/beta/edge/fleet-management](https://console.stage.redhat.com/beta/edge/fleet-management).

## Deploying MicroShift

As the Fleet Manager does not provide device configuration management yet, the demo uses the [Transmission](https://github.com/redhat-et/transmission) agent to stage configuration and other assets onto devices. It does so by polling the `GITOPS_REPO` for changes, using the device's Insights ID as the branch name for that repo.

Therefore, once the device is registered with Insights, look up the Insights ID on the Fleet Manager's info page for your device and store it:

    DEVICE_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # replace with your device's Insights ID

Log into your Open Cluster Management instance as admin using `oc`.

Finally, deploy MicroShift from the GitOps repo you created at the beginning using the following process:

    git clone ${GITOPS_REPO} microshift-config
    cd microshift-config
    git checkout -b ${DEVICE_ID}

    CLUSTER_NAME="microshift-demo"
    curl https://raw.githubusercontent.com/redhat-et/microshift-demos/main/e2e-demo/register_cluster.sh | bash -s - ${CLUSTER_NAME}

    git add .
    git commit -m "Update cluster name and ACM credentials"
    git push origin ${DEVICE_ID}

You should have a new branch named after your device's Insights ID in your repo with the configuration of OCM's `klusterlet` agent updated in `/var/lib/microshift/manifests`. The next time Transmission on your device checks for updates, it'll install MicroShift and apply the `klusterlet` configuration. A few moments after MicroShift starts, you should see the new cluster appearing in the OCM console.

## Deploying a Workload via Open Cluster Management

There is a lot of [documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.3/html/applications/index) on how to deploy a new application onto clusters managed by Open Cluster Management.

Follow these steps to deploy a sample application:

* Go to Open Cluster Management's application tab.
* Click on Create application button.
* Enter Name and Namespace for your application. Choose Git as repository type, and enter the URL of the git repo where your application manifests are stored and the placement policies you would like. The recommended one for this demo is *Deploy to all online clusters and local cluster*.
* Click on Save and wait for Open Cluster Management to create all the needed resources.

As an example, you can use the following [git repository](https://github.com/oglok/edge-app). It will deploy a replicated NGINX container and expose it on the 30303 port. Once this application is deployed, you should see the NGINX landing page with your browser using your device's IP address on the port mentioned above:

    http://DEVICE_IP:30303

Open Cluster Management allows you to view where the applications are deployed, and search for resources on specific clusters.
