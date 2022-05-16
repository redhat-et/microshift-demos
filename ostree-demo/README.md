# OSTree Demo

This demo introduces core technologies of RHEL for Edge, such as ImageBuilder, rpm-ostree, and greenboot. It then shows how to embed MicroShift into an ostree and deploy it.

Note the demo is deliberately low-level, walking through how to build OS images from the command line using the `composer-cli` tool, as this is what one would use to automate a GitOps pipeline for OS images. For building images graphically use the [web console](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/composing_installing_and_managing_rhel_for_edge_images/index#creating-a-blueprint-for-rhel-for-edge-images-using-web-console_composing-rhel-for-edge-images-using-image-builder-in-rhel-web-console) instead. For a full GitOps automation, see the [RHEL for Edge Automation Framework](https://github.com/redhat-cop/rhel-edge-automation-arch).

## Preparing the demo

### Pre-requisites

To build the ostrees and installer image, you need a RHEL 8.6 machine registered via `subscription-manager` and attached to a subscription that includes OCP4.8. You can add a trial evaluation for OCP at [Red Hat Customer Portal - Product Downloads](https://access.redhat.com/downloads). Once you register your RHEL installation, run `subscription-manager repos --enable="rhocp-4.8-for-rhel-8-x86_64-rpms"` to add the OCP repo. `appstream-rpms` and `baseos-rpms` are available by default.

Running `sudo subscription-manager repos --list-enabled | grep ID` should yield:

    Repo ID:   rhel-8-for-x86_64-appstream-rpms
    Repo ID:   rhel-8-for-x86_64-baseos-rpms
    Repo ID:   rhocp-4.8-for-rhel-8-x86_64-rpms

Install `git` if not yet installed and clone the demo repo:

    git clone https://github.com/redhat-et/microshift-demos.git
    cd microshift-demos/ostree-demo

Fork the demo's GitOps repo <https://github.com/redhat-et/microshift-config> into your own org and define the `GITOPS_REPO` environment variable accordingly:

    GITOPS_REPO="https://github.com/MY_ORG/microshift-config"

Set `UPGRADE_SERVER_IP` to the IP address of the current host:

    export UPGRADE_SERVER_IP=192.168.122.67

### Building the ostrees and installer image

Run the following to prepare for building the RHEL4Edge installer ISO containing the necessary MicroShift dependencies:

    ./prepare_builder.sh

Update the kickstart file to point to your forked GitOps repo and build the ostree and installer images:

    ./customize.sh
    ./build.sh

If all goes well, you should find the following files in `./builds`

    ostree-demo-0.0.1-container.tar
    ostree-demo-0.0.1-metadata.tar
    ostree-demo-0.0.1-logs.tar
    ostree-demo-0.0.2-container.tar
    ...
    ostree-demo-installer.x86_64.iso

## Running the demo

### Creating a first blueprint, building&serving an ostree

Have a look at `./blueprints/blueprint_v0.0.1.toml`, which defines a blueprint named `ostree-demo` that adds a few RPM packages for facilitating network troubleshooting to a base RHEL for Edge system, for example `arp`.

In a terminal, use the `composer-cli` tool to list previously uploaded blueprints, delete any existing `ostree-demo` blueprint, and upload the v0.0.1 blueprint:

    sudo composer-cli blueprints list
    sudo composer-cli blueprints delete ostree-demo
    sudo composer-cli blueprints push ./blueprints/blueprint_v0.0.1.toml

Start a build of that blueprint into an image of type `edge-container`:

    sudo composer-cli compose start-ostree --ref rhel/8/x86_64/edge ostree-demo edge-container

Specifying `edge-container` produces an OCI container image that contains both the ostree commit built from that the `ostree-demo` blueprint as well as an `ngingx` server that serves the ostree repo. This is makes testing, signing, and distributing the repo easy.

Check the status of the build with

    sudo composer-cli compose status

Note the compose build id output and assign it to `$BUILD_ID`. Once its status is `FINISHED`, download the `edge-container` image using

    sudo composer-cli compose image ${BUILD_ID}

The downloaded tarball can then be loaded into podman, tagged, and served locally:

    IMAGE_ID=$(cat ./${BUILD_ID}-container.tar | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
    sudo podman tag ${IMAGE_ID} localhost/ostree-demo:0.0.1
    sudo podman run -d --name=ostree-demo-server -p 8080:8080 localhost/ostree-demo:0.0.1

Check that the web server is running and serving the repo:

    curl http://localhost:8080/repo/config

If you want, check what the ostree repo looks like:

    sudo podman exec -it ostree-demo-server /bin/bash
    ls -l /usr/share/nginx/html

### Provisioning a VM with the ostree, looking around

Use your favorite virtualization solution to create a VM installed using the `./builds/ostree-demo-installer.x86_64.iso`. For example, to use `libvirt`, run

    ./prepare_virthost.sh
    sudo cp ./builds/ostree-demo-installer.x86_64.iso /var/lib/libvirt/images
    ./provision.sh

Note the VM must be able to reach the web server you're running on Podman.

After the VM boots, SSH into it using the login:pwd `redhat:redhat`. Have a look at the ostree filesystem:

    sudo ls -l /          # note most dirs are sym-linked to /var or /usr, there are new /ostree an /sysroot dirs
    sudo touch /usr/test  # /usr and most other dirs are mounted read-only
    sudo touch /etc/test  # /etc and /var are read-write

Most of the file system is read-only, which is key to enabling transactional updates and rollbacks. `/var` contains application state and therefore needs to be read-write and isn't changed during updates and rollbacks. `/etc` is contains system configuration and therefore needs to be read-write, too. Its content gets three-way-merged during updates and rollbacks.

Next, check the status of the ostree

    sudo rpm-ostree status

You'll get an output that looks somewhat like this:

    State: idle
    Deployments:
    ● ostree://edge:rhel/8/x86_64/edge
                    Version: 8.6 (2022-03-02T21:18:55Z)
                        Commit: 09f7284d4d0045e2529fea8730eb11161b2544ec6a796671e26f5f402699d332

This means the system has downloaded commit 09f7... from the remote ostree repo "edge" at ref "rhel/8/x86_64/edge" and has booted into it (marked by the ● ).

You can check the RPMs that ostree contains with

    sudo rpm-ostree db list rhel/8/x86_64/edge

You can also check whether new updates are available, which is currently not the case, of course:

    sudo rpm-ostree upgrade --check

### Updating the blueprint, updating and rolling back the device

Next, assume the operations team updates the blueprint to add the `iotop` package (see `./blueprints/blueprint_v0.0.2`), builds the updated ostree (`./builds/ostree-demo-0.0.2-container.tar`) and publishes it.

On the _host system_ run:

    IMAGE_ID=$(cat ./builds/ostree-demo-0.0.2-container.tar | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
    sudo podman tag ${IMAGE_ID} localhost/ostree-demo:0.0.2
    sudo podman rm -f ostree-demo-server
    sudo podman run -d --name=ostree-demo-server -p 8080:8080 localhost/ostree-demo:0.0.2

Now back on your VM console, check for available updates:

    sudo rpm-ostree upgrade --check

You'll see a new ostree commit being available and can check what changes it contains:

    sudo rpm-ostree upgrade --preview

You'll notice the update correctly adds the `iotop` package, but apparently someone made a mistake and accidentally removed the `bind-utils` package from the updated blueprint that provides the `dig` DNS client. Suppose `dig` was critical for the device's operation, for example to find its management system.

Verify that `dig` is still installed in the current version:

    which dig

Now let's stage the upgrade to the "broken" version 0.0.2:

    sudo rpm-ostree upgrade

Checking the ostree status, you'll note the system now has two ostree commmits, the new one being top of the list (it'll be booted by default) but not yet active (it has no ● ):

    sudo rpm-ostree status

Note also that `dig` is still present on the system:

    which dig

Now reboot into the updated system:

    sudo systemctl reboot

It just takes seconds until you can SSH back into the VM and verify the system has updated. You'll also notice `dig` is now missing from the system. Not good. Let's roll the system back to the previous ostree version:

    sudo rpm-ostree rollback
    sudo systemctl reboot

Again this just takes seconds. Verify the system is on the original ostree and has `dig` availble again.

### Rolling back automatically using greenboot

RHEL for Edge provides the `greenboot` tool that will run user-defined health checks and automatically roll back the a system update if those checks fail during multiple attempts. Let's add a check that fails when `dig` is not present on the system:

    sudo tee /etc/greenboot/check/required.d/01_check_deps.sh > /dev/null <<'EOF'
    #!/bin/bash

    if [ -x /usr/bin/dig ]; then
        echo "dig found, check passed!"
        exit 0
    else
        echo "dig not found, check failed!"
        exit 1
    fi
    EOF
    sudo chmod +x /etc/greenboot/check/required.d/01_check_deps.sh

Let's also add some logging for failed health checks:

    sudo tee /etc/greenboot/red.d/bootfail.sh > /dev/null <<'EOF'
    #!/bin/bash

    LOG="/var/roothome/greenboot.log"

    echo "greenboot detected a boot failure" >> $LOG
    date >> $LOG
    grub2-editenv list | grep boot_counter >> $LOG
    echo "----------------"  >> $LOG
    echo "" >> $LOG
    EOF
    sudo chmod +x /etc/greenboot/red.d/bootfail.sh

Let's retry the upgrade to the broken v0.0.2:

    sudo rpm-ostree upgrade
    sudo systemctl reboot

Watching the VM's console, you'll notice repeated attempts to boot into the updated system with the health check failing each time as `dig` is not present. After the third failed attempt, the system gets rolled back and booted into a "working" state again.

### Embedding and rolling out MicroShift

Next, let's add MicroShift to the blueprint (see `./blueprints/blueprint_v0.0.3.toml`) and "publish" the updated ostree repo.

On the _host system_ run:

    IMAGE_ID=$(cat ./builds/ostree-demo-0.0.3-container.tar | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
    sudo podman tag ${IMAGE_ID} localhost/ostree-demo:0.0.3
    sudo podman rm -f ostree-demo-server
    sudo podman run -d --name=ostree-demo-server -p 8080:8080 localhost/ostree-demo:0.0.3

Back on your VM console, upgrade the system to the latest ostree version:

    sudo rpm-ostree upgrade
    sudo systemctl reboot

You can now verify on the VM that MicroShift is installed and is starting up:

    systemctl status microshift

After a minute or so, you should be able to see the cluster running:

    mkdir -p ~/.kube
    sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig > ~/.kube/config
    oc get all -A

### Deploying workloads, connecting to Advanced Cluster Manager

For security reasons, production systems should not allow remote access via SSH or Kube API (e.g. `kubectl` or `oc`). Instead, you should use a device management agent of your choice to pull updates from your management system and apply them locally, for example to drop your workload's manifests into `/var/lib/microshift/manifests` and restart the MicroShift service.

For this demo, we'll use [Transmission](https://github.com/redhat-et/transmission) agent as lightweight way of configuring the devices using GitOps. Note the blueprint v0.0.3 already added this agent. On the VM, check that Transmission service is running:

    sudo systemctl status transmission

You'll also notice a journal entry like

    Mar 09 07:45:53 edge transmission[2505790]: 2022-03-09 07:45:53,102 INFO: Running update, URL is https://github.com/redhat-et/microshift-config?ref=89b0aea8-0ec5-e9e0-5644-0cd55b835532.

and on the login prompt on the VM's console you'll find the same URL. This points to the `${GITOPS}` repo you've set up at the very beginning. The Transmission agent on the device tries to clone that repo, check out the branch named after the ${DEVICE_ID} that uniquely identifies your device (here: 89b0...), and then roll the content of that branch into the running file system.

If you have an instance of Red Hat Advanced Cluster Mangagement (ACM) running and accessible from your machine via `oc`, then you can clone your GitOps repo, checkout the "ostree-demo" branch and see under `/var/lib/microshift/manifests` manifests for installing the ACM `klusterlet` agent and a `kustomization.yaml` for applying these manifests. What's missing is adding the cluster's name and ACM credentials to the manifests.

On the machine with ACM access, run:

    demo_dir=$(pwd)
    git clone "${GITOPS}" ostree-demo-config
    cd ostree-demo-config
    git checkout ostree-demo
    ${demo_dir}/register_cluster.sh "ostree-demo-cluster"
    git checkout -b ${DEVICE_ID}
    git push origin ${DEVICE_ID}

A few moments later, you should see your MicroShift cluster registered with ACM, ready to deploy workloads.
