# ============================================================================
# ArgoCD Bootstrap Script - App-of-Apps Pattern with Keycloak OIDC
# ============================================================================
# Minimal bootstrap: Create secrets, then deploy root application
# All infrastructure (NGINX, counting app, keycloak OIDC) auto-deploys via ArgoCD

# 1. Create namespaces
kubectl apply -f c:\code\argo-apps\argocd\bootstrap\namespaces.yaml

# 2. Create required secrets (manual prerequisite)
# ============================================================================
# These must exist before root app is deployed

# AWS credentials for External Secrets
kubectl create secret generic aws-credentials --from-literal=accessKeyID=$env:AWS_ACCESS_KEY --from-literal=secretAccessKey=$env:AWS_SECRET_KEY -n dev

# ArgoCD OIDC secret
kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=$env:KEYCLOAK_KEY -n argocd -l app.kubernetes.io/part-of=argocd

# ArgoCD TLS cert
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd
kubectl create secret tls counting-local-tls --cert=c:\certs\_wildcard.counting.local+1.pem --key=c:\certs\_wildcard.counting.local+1-key.pem -n dev
kubectl create secret tls cfb-local-tls --cert=c:\certs\_wildcard.cfb.local+1.pem --key=c:\certs\_wildcard.cfb.local+1-key.pem -n dev
kubectl create secret tls hello-local-tls --cert=c:\certs\_wildcard.hello.local+1.pem --key=c:\certs\_wildcard.hello.local+1-key.pem -n dev

# 3. Install ArgoCD bootstrap manifests (stable release)
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Create ArgoCD ingress
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\argocd-ingress.yaml

# 5. Create Keycloak  OIDC
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\argocd-keycloak-oidc.yaml

# 6. Create devtest project
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\project-devtest.yaml

# 7. Restart ArgoCD server
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 8. Deploy root application (scaffolds user applications and projects)
kubectl apply --server-side -f c:\code\argo-apps\argocd\root-app.yaml
kubectl wait --for=jsonpath='{.status.sync.status}'=Synced application/root -n argocd --timeout=300s

# ============================================================================
# VERIFICATION
# ============================================================================
# nginx-ingress takes ~5 minutes to go fully healthy
kubectl wait --for=jsonpath='{.status.health.status}'=Healthy application/nginx-ingress -n argocd --timeout=600s

# Verify all apps are synced:
kubectl get applications -n argocd

# ============================================================================
# ACCESS INSTRUCTIONS
# ============================================================================

# Access ArgoCD: https://argocd.local
# Access Counting App: https://dev.counting.local
# Get ArgoCD admin password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "^-- Copy admin password above"
echo "ArgoCD URL: https://argocd.local"
echo "Counting App URL: https://dev.counting.local"

# ============================================================================
# RBAC MANAGEMENT (GitOps)
# ============================================================================
# After initial bootstrap, RBAC policies are managed through GitOps.
# The argocd-rbac Application automatically syncs changes from:
#   argocd/rbac/argocd-rbac-cm.yaml
#
# To update RBAC policies:
# 1. Edit argocd/rbac/argocd-rbac-cm.yaml in git
# 2. Commit and push changes
# 3. ArgoCD will auto-sync the ConfigMap
# 4. Restart ArgoCD server: kubectl rollout restart deployment/argocd-server -n argocd

