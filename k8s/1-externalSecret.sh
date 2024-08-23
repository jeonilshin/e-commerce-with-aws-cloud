#!/bin/bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
   external-secrets/external-secrets \
   -n kube-system \
   --set serviceAccount.create=false