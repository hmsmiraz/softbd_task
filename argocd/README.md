# ArgoCD Setup

## Install ArgoCD on the cluster

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Wait for ArgoCD to be ready

```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## Get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then visit: https://localhost:8080

## Apply the ArgoCD manifests

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml
```

## ArgoCD will then automatically sync and deploy the Laravel app from GitHub.