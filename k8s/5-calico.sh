#!/bin/bash
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm show values projectcalico/tigera-operator --version v3.25.2
kubectl create namespace tigera-operator
echo '{ installation: {kubernetesProvider: EKS }}' > values.yaml
helm install calico projectcalico/tigera-operator --version v3.25.2 -f values.yaml --namespace tigera-operator
rm values.yaml
kubectl get all -n tigera-operator
kubectl get all -n calico-system