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

## Hubble Relay

```bash
helm upgrade cilium cilium/cilium \
   --version 1.17.3 \
   --namespace cilium \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
```

## Cluster Mesh

Maybe in the future? Who knows...