# Hello, MicroShift! Demo

This demo creates a minimal RHEL for Edge with MicroShift image and shows deploying a simple "Hello, MicroShift!" workload.

## Preparing the demo

Follow the instructions for [building demo images on a RHEL machine](https://github.com/redhat-et/microshift-demos/tree/main/README.md), building the demo with `./scripts/build hello-microshift-demo`.

## Running the demo
### Installing the ISO and accessing the MicroShift cluster

Install a VM or physical machine with the minimum system requirements (2 cores, 2GB RAM, 10GB disk) using the ISO at `./builds/hello-microshift-demo/hello-microshift-demo-installer.x86_64.iso`.

SSH into the machine:

    ssh -o "IdentitiesOnly=yes" -i ./builds/hello-microshift-demo/id_demo microshift@$MACHINE_IP

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

Add an entry to `/etc/hosts` to map the application's route to the host's IP address. The route FQDN is in the `routes/hello-microsoft` route object in the `demo` namespace. It will be `hello-microshift.local` but we'll use an oc command to output the route into a BASH variable named `route`. We then associate the host's IP to the route FQDN to the /etc/hosts file.

    hostIP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
    route=$(oc get routes/hello-microshift -n demo -o=jsonpath={.spec.host})
    sudo sed -i.bak '/hello-microshift.local/d' /etc/hosts
    echo "${hostIP}  ${route}" | sudo tee -a /etc/hosts

Now, trying to `curl` the application's route should return the "Hello, MicroShift!" HTML page:

    [microshift@edge ~]$ curl http://hello-microshift.local
    <!DOCTYPE html>
    <html>
    ...

### Accessing the cluster and "Hello, MicroShift!" application remotely

Next, let's access the cluster and application from outside the MicroShift machine.

If you're running the MicroShift on a VM _and_ your hypervisor connects instances via NAT, make sure to create port mappings from the hypervisor to guest ports 22 (ssh), 80 (http), and 6443 (K8s API).

Oo the MicroShift VM, ensure proper `firewalld` services are open. Use the following command on the MicroShift machine to open the services in the running config of `firewalld`.

    sudo firewall-cmd --add-service={ssh,http,kube-apiserver}

If you reboot the MicroShift machine, then these rules will be lost. To make the `firewalld` rules permanent, you may type on the MicroShift VM:

    sudo firewall-cmd --runtime-to-permanent

On your host that is attempting to access the MicroShift machine, you must to edit `/etc/hosts` to resolve `hello-microshift.local` to the MicroShift machine's IP, then you can `curl` the route and also access the page in your browser:

    [user@core ~]$ curl http://hello-microshift.local
    <!DOCTYPE html>
    <html>
    ...

To remotely access the cluster using the `oc` client, copy the kubeconfig from the MicroShift machine to your local machine. Then update the URL of the `server:` field in the kubeconfig to point to your MicroShift machine:

    mkdir -p ~/.kube
    ssh -o "IdentitiesOnly=yes" -i ./builds/hello-microshift-demo/id_demo microshift@$MACHINE_IP "sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig" > ~/.kube/config
    sed -i.bak 's|server: https://127.0.0.1:6443|server: https://hello-microshift.local:6443|' ~/.kube/config

Now you can access the cluster remotely. However, the `--insecure-skip-tls-verify=true` parameter must be set because the x509 on the MicroShift demo machine is not valid for `hello-microshift.local`. In production, an administrator would generate a proper x509 with a chain of trust, but this is just a demo.

    [user@core ~]$ oc --insecure-skip-tls-verify=true get pods -n demo
    NAME                                READY   STATUS    RESTARTS   AGE
    hello-microshift-6bdbc6c444-8sjc6   1/1     Running   0          45m
    hello-microshift-6bdbc6c444-bm5j4   1/1     Running   0          45m
