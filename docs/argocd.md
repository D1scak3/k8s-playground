# ArgoCD Autopilot

This chapter assumes you have `argocd` and `argocd-autopilot` clis installed.

If you don't have it installed:

- [argocd](https://argo-cd.readthedocs.io/en/stable/cli_installation/#download-latest-stable-version)
- [argocd-autopilot](https://argocd-autopilot.readthedocs.io/en/stable/Installation-Guide/#linux-and-wsl-using-curl)

## Installation

To install, follow along:

```bash
# export access token
export GIT_TOKEN=<your-token-here>

# export repo http link (same as if you were to clone the repo)
export GIT_URL=<your-url-here>

# then bootstrap ArgoCD into the cluster
argocd-autopilot repo bootstrap --provider=github
```

Don't forget to **retrive** the credentials generated from ArgoCD.

## Add cluster to deployment targets list

By default ArgoCD doesn't has any cluster contexts for deploying apps.
To solve this, add your cluster thorugh the `argocd` cli:

```bash
# port forward argocd-server service
kubectl port-forward svc/argocd-server 80:8080 -n argocd

# add cluster by targetting the port-forwarded service
argocd cluster add default --insecure --server localhost:8080
```

If you have been following along, the context of the created K3s cluster is `default`.
