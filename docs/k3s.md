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
# install k3s as a server(master) node
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" INSTALL_K3S_EXEC="server --flannel-backend=none --disable-network-policy"  sh -

# retrive token to add agent(worker) nodes in the future
sudo cat /var/lib/rancher/k3s/server/node-token

# retrive kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

When setting the kubeconfig, don't forget to change the IP in the `cluster.server` to the server node's IP.

## Calico CNI (Tigera Operator)

Before adding new nodes to the cluster, it is first needed to install Calico CNI, otherwise the addition of new nodes will fail.
Calico will be installed through the `tigera operator`, which in turn will be installed through `Helm Charts`.
After installing Calico, we will configure the isntallation through the `Installation` CRD provided by the Tigera
For more information consider reading the [helm docs](https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm) or their [github repo](https://github.com/projectcalico/calico/tree/master/charts/tigera-operator).

To install Calico, follow along:

```bash
# add helm repo
helm repo add projectcalico https://docs.tigera.io/calico/charts

# create namespace
kubectl create namespace tigera-operator

# install the operator
helm install calico projectcalico/tigera-operator --version v3.29.3 -f helm/calico/values.yaml --namespace tigera-operator

# to uninstall
helm uninstall calico projectcalico/tigera-operator -n tigera-operator
```

After installing the operator check the config of calico:

```bash
# check calico configuration
sudo cat /etc/cni/net.d/10-calico.conflist

# it should show this part in specific
...
"container_settings": {
  "allow_ip_forwarding": false
}
...
```

To update this value to `true`, we will update the `cni-config` ConfigMap resource that the Tigera Operator creates to configure Calico.
This is needed for K3s to allow traffic to the containers.

```bash
# patch the configmap to have the updated configuration regarding the container port forwarding
kubectl patch configmap/cni-config -n calico-system --patch-file="helm/calico/cni-config.yaml"

#restart the daemonset to update the config
kubectl rollout restart daemonset -n calico-system calico-node

# check the calico configmap again
# it should show the allow_id_forwaring to true
```

## Agent (worker) node

Install the K3s agent on the remaining VMs:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" K3S_TOKEN="K10bd1225585bbc791228b73ccf09f417b7e34a39827861ceeeb7aba6aea739bda6::server:c211afcea9a74f4109886af17c9f69b2" K3S_URL="https://192.168.124.11" sh -s -
```