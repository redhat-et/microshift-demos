# TopoLVM Demo
This demo walks through steps necessary to install the TopoLVM CSI plugin on top of MicroShift, running in a RHEL for Edge virtual machine.  Included with this demo are Kubernetes manifests derived from the [TopoLVM production deploy demo](topolvm/topolvm/deploy/README.md).

## Environment Configuration

This demo follows after the [MicroShift ostree demo](../ostree-demo). It is assumed that a RHEL for Edge guest OS is running and ready to upgrade to a MicroShift rpm-ostree layer (i.e. completed up through step [Provisioning a VM with the ostree, looking around](../ostree-demo#provisioning-a-vm-with-the-ostree-looking-around)). That said, these steps should work for MicroShift deployed to any supported OS.  To initialize a bring-your-own OS environment, see [Microshift documentation](https://microshift.io/docs/getting-started/).  

For reference, see the original [TopoLVM on Kubernetes demo](topolvm/topolvm/deploy/README.md)

The manifests in this demo were generated using [Helm](https://helm.sh/). See [TopoLVM helm charts](https://github.com/topolvm/topolvm/tree/main/charts/topolvm).  The following chart values were overridden for this demo:

- cert-manager.enabled=**true**
- lvmd.deviceClasses[0].volume-group=**vg_root**
- lvmd.deviceClasses[0].spare-gb=**9**
- controller.replicaCount=**1**

## Inject Config Files

SCP the systemd [unit file](./microshift.service) and [kube-scheduler-config.yaml](./kube-scheduler-config.yaml).

Login credentials are redhat:redhat.

```shell
VM_IP=<R4E Instance IP>
scp ./kube-scheduler-config.yaml ./microshift.service "$VM_IP":~/
ssh "$VM_IP" \
'sudo mkdir /etc/microshift && \
sudo mv ~/kube-scheduler-config.yaml /etc/microshift/ && \
sudo mv ~/microshift.service /etc/systemd/system/'
```

## Install and Start MicroShift

Execute ostree-demo step [Embedding and rolling out MicroShift](../ostree-demo/README.md#embedding-and-rolling-out-microshift) to install and start MicroShift.  Allow the instance to reboot and cluster a moment to stabilize before moving on.

```shell
ssh $VM_IP 'sudo rpm-ostree upgrade && sudo systemctl reboot'
```

## Install TopoLVM

Once the cluster node status is Ready and all cluster infra pods have entered the Running state, begin configuring the cluster for TopoLVM.

0. SCP over Kubernetes manifests

```shell
scp ./0_cert-manager.crds.yaml ./1_topolvm-manifests.yaml $VM_IP:~
```

_Shell into the R4E instance before proceeding._

2. Create the topolvm namespace and apply required resource labels.

```shell
export KUBECONFIG=/var/lib/microshift/resources/kubeadmin/kubeconfig
sudo oc new-project topolvm-system
sudo oc label namespace topolvm-system topolvm.cybozu.com/webhook=ignore
sudo oc label namespace kube-system topolvm.cybozu.com/webhook=ignore
```