#!/bin/bash

NAMESPACE='kube-system'
SA_NAME='f5xc'
SECRET_NAME='f5xc'
CONTEXT=$(kubectl config current-context)
CA_CRT=$(kubectl --namespace $NAMESPACE get secret/$SECRET_NAME -o json | jq -r '.data["ca.crt"]')
TOKEN=$(kubectl get secret/$SECRET_NAME -n $NAMESPACE -o json | jq -r .data.token | base64 --decode )
SERVER=$(kubectl config view -o json | jq -r --arg cluster_name "$CONTEXT" '.clusters[] | select(.name == $cluster_name) | .cluster.server')
CLUSTER_NAME=$(kubectl config view -o json | jq -r --arg cluster_name "$CONTEXT" '.clusters[] | select(.name == $cluster_name) | .name')

cat <<EOF > kubeconfig
---
apiVersion: v1
kind: Config
clusters:
- name: $CLUSTER_NAME
  cluster:
    certificate-authority-data: $CA_CRT  
    server: $SERVER
contexts:
- name: $SA_NAME-$CLUSTER_NAME
  context:
    cluster: $CLUSTER_NAME
    user: $SA_NAME
users:
- name: $SA_NAME
  user:
    token: $TOKEN
current-context: $SA_NAME-$CLUSTER_NAME
EOF