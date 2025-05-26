# Cilium CNI

## Installing

### Cilium Core (Operator and Envoy Daemonset)

```bash
# create namespace
kubectl create ns cilium

# add helm repo
helm repo add cilium https://helm.cilium.io/

# install helm in the cilium namespace
helm install cilium cilium/cilium \
   --namespace cilium \
   --values helm/cilium/values.yaml \
   --version 1.17.3

# install cilium cli
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# check status of cilium installation
cilium status --wait -n cilium

# test setup
# many tests will fail if you do not have an ingress class
cilium connectivity test -n cilium
```

### Hubble Relay

Hubble is already enabled in the `values.yaml` file, if you are not using it,
you can enable Hubble through this command:

```bash
helm upgrade cilium cilium/cilium \
   --version 1.17.3 \
   --namespace cilium \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
```

### Cluster Mesh

Maybe in the future? Who knows...

## Uninstalling

```bash
helm uninstall cilium -n cilium
```

## Upgrading/Updating 

After upgrading or updating Cilium, it is recommended to restart all deployments and daemonsets in order to apply the new configs:

```bash
kubectl -n cilium rollout restart deployment/cilium-operator

kubectl -n cilium rollout restart ds/cilium
```

## Ingress setup

Cilium has an Ingress implementation uses the original Kubernetes Ingress resource, with extra functionalities and complexity.

To enable and use the Cilium Ingress as the default IngressClass, it is necessary to configure the following values in the [/helm/cilium/values.yaml](/helm/cilium/values.yaml) file:

```yaml
...
ingressController:
   enabled: true
   default: true
   loadbalancerMode: shared
...
```

These values enable Cilium Ingress. A unique `LoadBalancer` type service is created in order to redirect incoming traffic to the desired service.

This approach is simpler and easier. For more complex and bigger setups, it is recommended to use the ``ingressController.loadbalancerMode=dedicated`. For more information check the official [docs](https://docs.cilium.io/en/stable/network/servicemesh/ingress/).

### Available Ingresses

All DNS names were defined locally on `/etc/hosts` file.

| Service |          DNS          |
| :-----: | :-------------------: |
| Grafana | grafana.playground.io |