# Traefik

```bash
# add helm repo
helm repo add traefik https://traefik.github.io/charts

# create namespace
kubectl create ns traefik

# install traefik
helm install traefik traefik/traefik --version 35.2.0 --namespace traefik
```