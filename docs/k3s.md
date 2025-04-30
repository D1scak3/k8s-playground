# K3s installation guide

The K3s cluster will be composed by 3 nodes (1 master and 2 workers).
The installed version is `v1.32.3+k3s1`.

| K3S Version |   CSI    |  CNI   |       |       |
| :---------: | :------: | :----: | :---: | :---: |
|             | Longhorn | Calico |       |       |
|             |          |        |       |       |
|             |          |        |       |       |

## Server (master) node

Install the K3s server on one of the VMs:

```bash
# disable firewalld
sudo systemctl disable firewalld --now

# install k3s as a server(master) node
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server --flannel-backend=none --disable-network-policy --disable=traefik,local-storage"  sh -

# retrive token to add agent(worker) nodes in the future
sudo cat /var/lib/rancher/k3s/server/node-token
K1009c18d0fd12040c34fb8cad9828761393e078059cfe6dbd9b38391af412924a2::server:8dedfabba2a52f2989d55032afdec1e2

# set kubeconfig for local access inside the VM
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config

# retrive kubeconfig for external access
# don't forget to change the IP to the VM IP
sudo cat /etc/rancher/k3s/k3s.yaml
```

When setting the kubeconfig, don't forget to change the IP in the `cluster.server` to the server node's IP.

## Cilium CNI

```bash
# create namespace
kubectl create ns cilium

# add helm repo
helm repo add cilium https://helm.cilium.io/

# install helm in the cilium namespace
helm install cilium cilium/cilium --version 1.17.3 \
   --namespace cilium \
   --set operator.replicas=1

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

## Traefik

```bash
# add helm repo
helm repo add traefik https://traefik.github.io/charts

# create namespace
kubectl create ns traefik

# install traefik
helm install traefik traefik/traefik --version 35.2.0 --namespace traefik
```

## Agent (worker) node

Install the K3s agent on the remaining VMs:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" \
K3S_TOKEN="K1009c18d0fd12040c34fb8cad9828761393e078059cfe6dbd9b38391af412924a2::server:8dedfabba2a52f2989d55032afdec1e2" \
K3S_URL="https://192.168.124.11:6443" sh -
```