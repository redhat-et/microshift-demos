# Hello, MicroShift! Demo

This demo creates a minimal RHEL for Edge with MicroShift image and shows deploying a simple "Hello, MicroShift!" workload.

## Preparing the demo

Follow the instructions for [building demo images on a RHEL machine](https://github.com/redhat-et/microshift-demos/tree/main/README.md), building the demo with `./scripts/build hello-microshift-demo`.

## Running the demo
### Installing the ISO and accessing the MicroShift cluster

Install a VM or physical machine with the minimum system requirements (2 cores, 2GB RAM, 10GB disk) using the ISO at `./builds/hello-microshift-demo/hello-microshift-demo-installer.x86_64.iso`.

SSH into the machine:

    ssh -o "IdentitiesOnly=yes" -i ./builds/hello-microshift/demo/id_demo microshift@$MACHINE_IP

Verify that the MicroShift service has started:

    sudo systemctl status microshift

Verify that you can access MicroShift locally:

    oc get all -A

Now wait for MicroShift to be fully up-and-running. This may take a few minutes the first time MicroShift starts, because it still needs to pull the container images it deploys. When it's ready, `oc get pods -A` output should look similar to:

    NAMESPACE                  NAME                                      READY   STATUS    RESTARTS   AGE
    openshift-dns              pod/dns-default-lm55n                     2/2     Running   0          80s
    openshift-dns              pod/node-resolver-zp7gw                   1/1     Running   0          3m11s
    openshift-ingress          pod/router-default-ddc545d88-mk8gc        1/1     Running   0          3m5s
    openshift-ovn-kubernetes   pod/ovnkube-master-4586k                  4/4     Running   0          3m11s
    openshift-ovn-kubernetes   pod/ovnkube-node-xgx9t                    1/1     Running   0          3m11s
    openshift-service-ca       pod/service-ca-77fc4cc659-ncmbv           1/1     Running   0          3m6s
    openshift-storage          pod/topolvm-controller-5fc9996875-lzpgx   4/4     Running   0          3m12s
    openshift-storage          pod/topolvm-node-hb5mh                    4/4     Running   0          80s

### Deploying the "Hello, MicroShift!" application and accessing it locally

Now let's deploy the "Hello, MicroShift!" application:

    oc apply -k https://github.com/redhat-et/microshift-demos/apps/hello-microshift?ref=main

Verify that the application is deployed and the route is accepted:

    [microshift@edge ~]$ oc get pods -n demo
    NAME                                READY   STATUS    RESTARTS   AGE
    hello-microshift-6bdbc6c444-nnhrm   1/1     Running   0          24s
    hello-microshift-6bdbc6c444-zp5cc   1/1     Running   0          24s

    [microshift@edge ~]$ oc get routes -n demo
    NAME               HOST                     ADMITTED   SERVICE            TLS
    hello-microshift   hello-microshift.local   True       hello-microshift

Add an entry to `/etc/hosts` to map the application's route (`hello-microshift.local`) to the machine's primary IP:

    hostIP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
    sudo sed -i '/hello-microshift.local/d' /etc/hosts
    echo "${hostIP}  hello-microshift.local" | sudo tee -a /etc/hosts

Now, try `curl`ing the applications route should return the "Hello, MicroShift!" HTML page:

    [microshift@edge ~]$ curl http://hello-microshift.local
    <!DOCTYPE html>
    <html>
    ...
