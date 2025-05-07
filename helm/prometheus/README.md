# Kube Prometheus

For reference:

- https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack

## Installing

```bash
# add helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# update the repos
helm repo update

# create namespace
kubectl create ns prometheus

# install helm
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace prometheus \
    --values helm/prometheus/values.yaml \
    --version 71.1.01
```

## Uninstalling

```bash
# remove helm
helm uninstall prometheus prometheus-community/kube-prometheus-stack \
    --namespace prometheus

# delete the leftover CRDs
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheusagents.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd scrapeconfigs.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```