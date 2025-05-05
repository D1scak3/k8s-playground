# Traefik

# Install

```bash
# add helm repo
helm repo add traefik https://traefik.github.io/charts

# create namespace
kubectl create ns traefik

# install traefik
helm install traefik traefik/traefik \
    --namespace traefik \
    --values helm/traefik/values.yaml \
    --version 35.2.0
```

## Uninstall

```bash
helm uninstall traefik traefik/traefik --namespace traefik
```