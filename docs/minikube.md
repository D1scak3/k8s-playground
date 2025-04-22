# Minikube setup

To create a multi node cluster in Minikube run the following command:

```bash
# run this command as many times as clusters you want
minikube start --addons=metallb,storage-provisioner-rancher --cpus=2 --memory=2G --driver=docker --disk-size="4g" --subnet="192.168.50.0" --service-cluster-ip-range="10.96.0.0/24" -n 3 -p cluster1

minikube start --addons=metallb,storage-provisioner-rancher --cpus=2 --memory=2G --driver=docker --disk-size="4g" --subnet="192.168.50.0" --service-cluster-ip-range="10.97.0.0/24" -n 3 -p cluster2
```