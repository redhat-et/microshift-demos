#! /usr/bin/env bash

set -euo pipefail

if ! command -v yq &> /dev/null
then
  mkdir -p $HOME/bin
  wget https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64 -O $HOME/bin/yq
  chmod +x $HOME/bin/yq
  yq --version
fi

MANIFESTS_DIR=$(git rev-parse --show-toplevel)/var/lib/microshift/manifests
if [ ! -d "${MANIFESTS_DIR}" ]
then
  echo "No klusterlet manifests found in ${MANIFESTS_DIR}. Are you in the config git repo?"
  exit 1
fi

CLUSTER_NAME=${1:? "\$1 should be a cluster name (host part of the cluster's FQDN)"}

WORK_DIR=$HOME/.acm/"$CLUSTER_NAME"
SPOKE_DIR="$WORK_DIR"/spoke
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$SPOKE_DIR"

cat <<EOF >"$WORK_DIR"/managed-cluster.yaml
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: "$CLUSTER_NAME"
spec:
  hubAcceptsClient: true
EOF

cat <<EOF >"$WORK_DIR"/klusterlet-addon-config.yaml
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: "$CLUSTER_NAME"
  namespace: "$CLUSTER_NAME"
spec:
  clusterName: "$CLUSTER_NAME"
  clusterNamespace: "$CLUSTER_NAME"
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

oc new-project "$CLUSTER_NAME" 1>/dev/null
oc label namespace "$CLUSTER_NAME" cluster.open-cluster-management.io/managedCluster="$CLUSTER_NAME"
oc apply -f "$WORK_DIR"/managed-cluster.yaml
oc apply -f "$WORK_DIR"/klusterlet-addon-config.yaml

sleep 3

oc get secret "$CLUSTER_NAME"-import -n "$CLUSTER_NAME" -o jsonpath={.data.import\\.yaml} | base64 --decode > "$SPOKE_DIR"/import.yaml

KUBECONFIG=$(yq eval-all '. | select(.metadata.name == "bootstrap-hub-kubeconfig") | .data.kubeconfig' "$SPOKE_DIR"/import.yaml)
sed -i "s/{{ .clustername }}/${CLUSTER_NAME}/g" ${MANIFESTS_DIR}/klusterlet.yaml
sed -i "s/{{ .kubeconfig }}/${KUBECONFIG}/g" ${MANIFESTS_DIR}/klusterlet-kubeconfighub.yaml
