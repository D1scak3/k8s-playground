# Cert Manager

Cert Manager allow for easy creation and management of certificates inside Kubernetes.
It easely integrates with Ingress, which facilitates securing of exposed services.

## Install

```bash
# create namespace
kubectl create ns cert-manager

# add helm repo
helm repo add jetstack https://charts.jetstack.io --force-update

# update repo
hel repo update

# install cert-manager
helm install cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.17.2 \
    --set crds.enabled=true
```

## Uninstall

```bash
helm uninstall cert-manager -n cert-manager
```

## How it works

Cert Manager was configured to self-sign every certificate that the cluster will use.

The [manifests](/helm/cert-manager/manifests/) folder holds the CRs which will enable the self-signing of certificates:

- the "selfsigned-issuer" `ClusterIssuer` is used to **issue the Root CA Certificate**. Somewhat of a "bootstrap issuer";
- the "my-selfsigned-ca" `Certificate` is the **Root CA Certificate**;
- the "my-ca-issuer" `ClusterIssuer` is used to isse but also **sign certificates using the newly created Root CA Certificate**, which is what will be used for future certifiaces cluster-wide;
