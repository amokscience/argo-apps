# ============================================================================
# ArgoCD Bootstrap Script - App-of-Apps Pattern with Keycloak OIDC
# ============================================================================
# Minimal bootstrap: Create secrets, then deploy root application
# All infrastructure (NGINX, counting app, keycloak OIDC) auto-deploys via ArgoCD

# 1. Create namespaces
kubectl create namespace argocd
kubectl create namespace dev
kubectl create secret generic aws-credentials --from-literal=accessKeyID=$env:AWS_ACCESS_KEY --from-literal=secretAccessKey=$env:AWS_SECRET_KEY -n dev

# 2. Create required secrets (manual prerequisite)
# ============================================================================
# These must exist before root app is deployed

# ArgoCD OIDC secret
kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=$env:KEYCLOAK_KEY -n argocd
kubectl label secret argocd-oidc-keycloak app.kubernetes.io/part-of=argocd -n argocd

# ArgoCD TLS cert
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd
kubectl create secret tls counting-local-tls --cert=c:\certs\_wildcard.counting.local+1.pem --key=c:\certs\_wildcard.counting.local+1-key.pem -n dev
kubectl create secret tls cfb-local-tls --cert=c:\certs\_wildcard.cfb.local+1.pem --key=c:\certs\_wildcard.cfb.local+1-key.pem -n dev
kubectl create secret tls hello-local-tls --cert=c:\certs\_wildcard.hello.local+1.pem --key=c:\certs\_wildcard.hello.local+1-key.pem -n dev

# 3. Install ArgoCD bootstrap manifests (stable release)
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Create ArgoCD ingress and OIDC config (direct apply, not via app-of-apps)
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\argocd-ingress.yaml
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\argocd-keycloak-oidc.yaml
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\project-devtest.yaml

# 5. Restart ArgoCD server
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 7. Deploy root application (scaffolds user applications and projects)
kubectl apply --server-side -f c:\code\argo-apps\argocd\root-app.yaml
kubectl wait --for=jsonpath='{.status.sync.status}'=Synced application/root -n argocd --timeout=300s

# ============================================================================
# VERIFICATION
# ============================================================================
# Verify all apps are synced:
kubectl get applications -n argocd

# ============================================================================
# ACCESS INSTRUCTIONS
# ============================================================================

# 2. Access ArgoCD: https://argocd.local
# 3. Access Counting App: https://dev.counting.local
# 4. Get ArgoCD admin password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "^-- Copy admin password above"
echo "ArgoCD URL: https://argocd.local"
echo "Counting App URL: https://dev.counting.local"
