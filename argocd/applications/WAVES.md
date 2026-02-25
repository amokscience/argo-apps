# ArgoCD Sync Waves

This folder uses **non-negative sync waves** starting at `0`.

## Convention

1. Prefix each application manifest filename with its wave number:
   - `0-...yaml`, `1-...yaml`, `2-...yaml`, etc.
2. Add the matching annotation in the manifest metadata:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "<wave-number>"
```

Keep the filename prefix and annotation value aligned.

## Current Wave Layout

### Wave 0 (foundation)
- `0-project-sandbox.yaml`
- `0-argocd-rbac-app.yaml`

### Wave 1 (platform dependencies)
- `1-external-secrets-operator-app.yaml`
- `1-nginx-ingress-app.yaml`

### Wave 2 (observability)
- `2-monitoring-stack-app.yaml`

### Wave 3 (low-risk apps)
- `3-dev-hello-app.yaml`
- `3-dev-counting-app.yaml`

### Wave 4 (core apps)
- `4-dev-cfb-app.yaml`
- `4-dev-knfo-app.yaml`
- `4-dev-ntest-app.yaml`

## Adding a New App

- Choose the wave based on dependencies.
- Name the file with the same leading wave number.
- Set `argocd.argoproj.io/sync-wave` to that number.
- Place the file in this directory so the root app discovers it.
