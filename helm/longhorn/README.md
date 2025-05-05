# Longhorn

## Install

```bash
# add helm repo
helm repo add longhorn https://charts.longhorn.io

# update repo
helm repo update

# create namespace
kubectl create ns longhorn

# install longhorn
helm install longhorn longhorn/longhorn \
    --namespace longhorn \
    --values helm/traefik/values.yaml \
    --version 1.8.1
```

## Uninstall

```bash
helm uninstall longhorn longhorn/longhorn --namespace longhorn
```
