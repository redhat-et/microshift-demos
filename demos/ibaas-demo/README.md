# MicroShift Image Builder as a Service

This demo will allow you to build a RHEL for Edge 8 image containing MicroShift and all its dependencies by using the hosted Image Builder service running at `console.redhat.com`. This new Red Hat managed service is a great tool for users to build different customized RHEL images without the need to have specific infrastructure on premise. 

## Pre-requisites

This demo has two basic requirements:

* A RHEL/Fedora machine to be able to execute a simple bash script
* An AWS account in order to create an S3 bucket where the automation will host some files.

## Demo workflow

The main script called `run.sh` will get you through the following steps:

* Download the MicroShift official repository and locally build RPM packages.
* Install the AWS CLI and configure it with your own account credentials.
* Create an S3 bucket and store the MicroShift packages as an RPM repo.
* Call hosted Image Builder service in `console.redhat.com` to build an ostree-commit with all the required packages.
* Host the ostree-commit into the recently created S3 bucket.
* Call hosted Image Builder service to create an ISO image using that ostree-commit.
* Inject a kickstart file that will configure the system for MicroShift.


## Demo execution

Go to the demo folder `demos/ibaas-demo/` and run the following command with your own parameters:

```
./run.sh RHUSER PASSWORD BUCKET-NAME PULLSECRET

```

where:
* RHUSER: user of your Red Hat account
* PASSWORD: password of your Red Hat account
* BUCKET-NAME: name to create a new S3 bucket on your AWS account
* PULLSECRET: path to a file containing your Red Hat's [pull secret](https://console.redhat.com/openshift/install/pull-secret


The resulting ISO image will be stored in the following directory under `builds/iso/`. You can use this ISO to install it in a VM or a physical machine. We have created a simple user to allow you to login `redhat/redhat`, but we encourage you to change the password inmediately.