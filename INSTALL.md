# ============================================================================
# ArgoCD Bootstrap Script - App-of-Apps Pattern with Keycloak OIDC
# ============================================================================
# Minimal bootstrap: Create secrets, then deploy root application
# All infrastructure (NGINX, counting app, keycloak OIDC) auto-deploys via ArgoCD

# 1. Create namespaces
kubectl create namespace argocd
kubectl create namespace dev

# 2. Create required secrets (manual prerequisite)
# ============================================================================
# These must exist before root app is deployed

# ArgoCD OIDC secret
kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=RyTihUdhH8ahTO6MIHJCkQ7DmolHlM3c -n argocd
kubectl label secret argocd-oidc-keycloak app.kubernetes.io/part-of=argocd -n argocd

# ArgoCD TLS cert
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd

# Counting app TLS cert (wildcard for *.counting.local)
kubectl create secret tls counting-local-tls --cert=c:\certs\_wildcard.counting.local+1.pem --key=c:\certs\_wildcard.counting.local+1-key.pem -n dev

# 3. Install ArgoCD bootstrap manifests (stable release)
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Create ArgoCD ingress and OIDC config (direct apply, not via app-of-apps)
# These are prerequisites for ArgoCD to function, not user applications
kubectl apply --server-side -f c:\code\argo-apps\argocd\applications\argocd-ingress.yaml
kubectl apply --server-side -f c:\code\argo-apps\argocd\applications\argocd-keycloak-oidc.yaml

# 5. Restart ArgoCD server
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 6. Deploy root application (scaffolds user applications and projects)
# ============================================================================
# This single Application discovers and creates:
#   - AppProjects (argocd/applications/projects/)
#   - User apps (argocd/applications/)
#     - nginx-ingress (NGINX Ingress Controller)
#     - counting-dev (Counting application with ingress)
# 
# Note: ArgoCD OIDC config is applied directly above as a prerequisite,
# not managed by app-of-apps
kubectl apply --server-side -f c:\code\argo-apps\argocd\root-app.yaml
kubectl wait --for=condition=available --timeout=300s application/root -n argocd

# ============================================================================
# VERIFICATION
# ============================================================================
# Verify all apps are synced:
kubectl get applications -n argocd
argocd app list

# ============================================================================
# ACCESS INSTRUCTIONS
# ============================================================================

# 1. Add to hosts file (C:\Windows\System32\drivers\etc\hosts): 
#    127.0.0.1 argocd.local
#    127.0.0.1 dev.counting.local
#
# 2. Access ArgoCD: https://argocd.local
# 3. Access Counting App: https://dev.counting.local
#
# 4. Get ArgoCD admin password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "^-- Copy admin password above"
echo "ArgoCD URL: https://argocd.local"
echo "Counting App URL: https://dev.counting.local"
