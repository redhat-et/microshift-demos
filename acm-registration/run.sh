#!/bin/bash
curl  -L -o /opt/kubeconfig https://gist.githubusercontent.com/copejon/107640027c8eae93af83fd7785677cd4/raw/38145da8299f6672287831f4e72e79fd425a9fbe/gistfile1.txt
export KUBECONFIG=/opt/kubeconfig
oc config use-context acm
./acm-hub.sh ushift
oc config use-context microshift
./acm-spoke.sh ushift
