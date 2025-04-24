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
# ssh to node1
ssh node1@192.168.124.11

# install k3s as a server(master) node
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" INSTALL_K3S_EXEC="server --flannel-backend=none --disable-network-policy"  sh -

# retrive token to add agent(worker) nodes in the future
sudo cat /var/lib/rancher/k3s/server/node-token

# retrive kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

When setting the kubeconfig, don't forget to change the IP in the `cluster.server` to the server node's IP.

## Agent (worker) node
