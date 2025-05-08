# K8s Playground

This repository holds all information regarding how to setup a K3s cluster through Libvirt.

This cluster was created with the aim to explore and test K8s based solutions in a more robust environments
when compared to more popular solutions (Minikube, Kind, etc...).

## Index

Main topics for cluster creation:

- [Vm setup](/docs/vm.md)
- [K3s cluster creation](/docs/k3s.md)
- [K3s uninstallation](/docs/uninstall.md)


## Cluster specs

### Nodes

|  Node Type  | Amount |  CPU  |   RAM   | DISK  |       OS       |
| :---------: | :----: | :---: | :-----: | :---: | :------------: |
| Server node |   1    |   2   | 4096Mib | 30Gib | Rocky Linux9.5 |
| Agent node  |   2    |   2   | 4096Mib | 25Gib | Rocky Linux9.5 |

### Cluster Services

| Service         | Helm Chart Version | Purpose                                                                   |
| --------------- | ------------------ | ------------------------------------------------------------------------- |
| Cilium CNI      | 1.17.3             | Network connectivity, security, and observability for containers          |
| Kube-Prometheus | 71.1.01            | Monitoring and alerting for Kubernetes clusters                           |
| LGTM Stack      | 2.1.0              | Log collection, visualization, and analysis (Loki, Grafana, Tempo, Mimir) |
| Traefik         | 35.2.0             | Ingress controller and edge router for services                           |
| Longhorn        | 1.8.1              | Distributed block storage system for Kubernetes                           |
