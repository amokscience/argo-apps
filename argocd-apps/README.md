# ArgoCD Applications Setup

This directory contains all the Kubernetes manifests and ArgoCD configurations for deploying the front-end and sql-service applications across multiple environments (dev, qa, staging, prod).

## Directory Structure

```
argocd-apps/
├── namespaces/
│   └── namespaces.yaml           # Creates dev, qa, staging, prod namespaces
├── applications/
│   ├── front-end-*.yaml          # ArgoCD Application resources (one per environment)
│   └── sql-service-*.yaml        # ArgoCD Application resources (one per environment)
├── front-end/
│   ├── base/                     # Base deployment/service definitions
│   └── overlays/                 # Environment-specific overrides (dev, qa, staging, prod)
└── sql-service/
    ├── base/                     # Base deployment/service definitions
    └── overlays/                 # Environment-specific overrides (dev, qa, staging, prod)
```

## What's Configured

### Namespaces
- **dev** - Development environment
- **qa** - Quality Assurance environment
- **staging** - Staging environment
- **prod** - Production environment

### Services
Both services are configured with:
- **Replicas**: 3 instances per environment
- **Resources**: Minimal CPU (100m request, 500m limit) and Memory (128Mi request, 512Mi limit)
- **ENVIRONMENT variable**: Automatically set per environment (dev, qa, staging, prod)
- **Container images**: `amokscience/front-end` and `amokscience/sql-service` (both `:latest` tag)

### Port Mappings
- **front-end**: 8040
- **sql-service**: 8009

## Setup Instructions

### 1. Push to GitHub
Commit and push all files to your `amokscience/argo-apps` GitHub repository:

```bash
git add .
git commit -m "Add ArgoCD applications for front-end and sql-service"
git push origin main
```

### 2. Create ArgoCD Applications

Apply the namespace definitions first:
```bash
kubectl apply -f argocd-apps/namespaces/namespaces.yaml
```

Then apply all ArgoCD Application resources:
```bash
kubectl apply -f argocd-apps/applications/
```

Alternatively, use ArgoCD CLI:
```bash
argocd app create --file argocd-apps/applications/front-end-dev.yaml
argocd app create --file argocd-apps/applications/front-end-qa.yaml
argocd app create --file argocd-apps/applications/front-end-staging.yaml
argocd app create --file argocd-apps/applications/front-end-prod.yaml
argocd app create --file argocd-apps/applications/sql-service-dev.yaml
argocd app create --file argocd-apps/applications/sql-service-qa.yaml
argocd app create --file argocd-apps/applications/sql-service-staging.yaml
argocd app create --file argocd-apps/applications/sql-service-prod.yaml
```

### 3. Verify Applications

Check the status of applications:
```bash
argocd app list
argocd app get front-end-dev
argocd app sync front-end-dev
```

Or using kubectl:
```bash
kubectl get applications -n argocd
kubectl describe app front-end-dev -n argocd
```

## Customization

### Adding Secrets
Each environment overlay can have secrets defined. Create a `secrets.yaml` in the overlay folder:

```yaml
# argocd-apps/front-end/overlays/dev/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: front-end-secrets
type: Opaque
stringData:
  API_KEY: your-dev-api-key
  DATABASE_URL: postgres://dev-db:5432/myapp
```

Reference in deployment:
```yaml
env:
- name: API_KEY
  valueFrom:
    secretKeyRef:
      name: front-end-secrets
      key: API_KEY
```

### Adding More Environment Variables
Edit the kustomization.yaml in each overlay to add more configMap entries:

```yaml
configMapGenerator:
- name: front-end-config
  literals:
  - environment=dev
  - LOG_LEVEL=debug
  - API_ENDPOINT=https://api-dev.example.com
```

### Changing Image Tags
Modify the deployment.yaml in the base folder or add an image patch in the overlay:

```yaml
# In overlay/dev/kustomization.yaml
images:
- name: amokscience/front-end
  newTag: v1.2.3
```

### Auto-Sync Policy
All applications are configured with auto-sync enabled:
- **prune: true** - Deletes resources removed from the source
- **selfHeal: true** - Automatically corrects cluster state to match the source

To disable auto-sync, edit the Application and set:
```yaml
syncPolicy:
  automated: null
```

## Monitoring

### ArgoCD Dashboard
Access the ArgoCD dashboard (typically on port 8080):
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### Check Sync Status
```bash
argocd app sync-status front-end-dev
argocd app logs front-end-dev
```

### Troubleshooting
View deployment logs:
```bash
kubectl logs -n dev deployment/dev-front-end
kubectl logs -n dev deployment/dev-sql-service
```

## Next Steps

1. **Add Additional Secrets**: Create secret manifests for API keys, database credentials, etc.
2. **Configure Image Updates**: Update the deployment tags when deploying specific versions
3. **Add Ingress**: If you need external access, add Ingress resources to the overlays
4. **Set Resource Quotas**: Consider adding ResourceQuota and LimitRange to each namespace
5. **Add Health Checks**: Configure liveness and readiness probes in deployments
