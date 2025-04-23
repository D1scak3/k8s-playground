# K3s installation guide

The K3s cluster will be composed by 3 nodes (1 master and 2 workers).

## Server (master) node

The main node is present at 192.168.124.11 with the hostname `node1`:

```bash
# ssh to node1
ssh node1@192.168.124.11

# install k3s as a server(master) node
curl -sfL https://get.k3s.io | sh -

# retrive token to add agent(worker) nodes in the future
sudo cat /var/lib/rancher/k3s/server/node-token

# retrive kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

When setting the kubeconfig, don't forget to change the IP in the `cluster.server` to the `node1` IP.