#! /usr/bin/env bash

set -eu


CLUSTER_NAME=${1:?"expected the cluster name, required to find import data"}
BUCKET=acm-microshift-demo
aws s3 cp --recursive s3://$BUCKET/$CLUSTER_NAME /var/lib/microshift/manifests

