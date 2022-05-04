# TopoLVM Demo
This demo walks through steps necessary to install the TopoLVM CSI plugin on top of MicroShift, running in a RHEL for Edge virtual machine.  Included with this demo are Kubernetes manifests derived from the [TopoLVM production deploy demo](topolvm/topolvm/deploy/README.md).

## Requirements

## Setup the Environment

This demo follows after the [MicroShift ostree demo](../ostree-demo). It is assumed that a RHEL for Edge guest OS is running and ready to upgrade to a MicroShift rpm-ostree layer (i.e. completed up through step [Provisioning a VM with the ostree, looking around](../ostree-demo#Provisioning_a_VM_with_the_ostree,_looking_around)). That said, these steps should work for MicroShift deployed to any supported OS.  To initialize a bring-your-own OS environment, see [Microshift documentation](https://microshift.io/docs/getting-started/).  

For reference, see the original [TopoLVM on Kubernetes demo](topolvm/topolvm/deploy/README.md)

The manifests in this demo were generated using [Helm](https://helm.sh/). See [TopoLVM helm charts](https://github.com/topolvm/topolvm/tree/main/charts/topolvm).  The following chart values were overridden for this demo:

- cert-manager.enabled=**true**
- lvmd.deviceClasses[0].volume-group=**vg_root**
- lvmd.deviceClasses[0].spare-gb=**9**
- controller.replicaCount=**1**

## Configuration

TopoLVM can be deployed before or after MicroShift has been installed and started. This document assumes the MicroShift ostree layer has not yet been installed.

It is not necessary to download the topolvm repository

### Inject Config Files

SCP the systemd [unit file](./microshift.service) and [kube-scheduler-config.yaml](./kube-scheduler-config.yaml).

Login credentials are redhat:redhat.

```shell
VM_IP=<R4E Instance IP>
scp ./kube-scheduler-config.yaml ./microshift.service "$VM_IP":~/
ssh "$VM_IP" \
'sudo mkdir /etc/microshift.d && \
sudo mv ~/kube-scheduler-config.yaml /etc/microshift.d/ && \
sudo mv ~/microshift.service /etc/systemd/system/'
```