# LGTM stack

For reference:

- https://artifacthub.io/packages/helm/grafana/lgtm-distributed

## Installing

```bash
# add helm repo
helm repo add grafana https://grafana.github.io/helm-charts

# update the repos
helm repo update

# create namespace
kubectl create ns lgtm

# install helm
helm install lgtm grafana/lgtm-distributed \
    --namespace lgtm \
    --values helm/lgtm/values.yaml \
    --version 2.1.0
```

## Uninstalling

```bash
helm uninstall lgtm grafana/lgtm-distributed \
    --namespace lgtm
```