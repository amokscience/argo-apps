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
kubectl create secret generic argocd-notifications-secret --from-literal=slack-api-url=$env:SLACK_WEBHOOK -n argocd

# ArgoCD OIDC secret
kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=$env:KEYCLOAK_KEY -n argocd
kubectl label secret argocd-oidc-keycloak app.kubernetes.io/part-of=argocd -n argocd

# TLS certificates
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd
kubectl create secret tls counting-tls --cert=c:\certs\_wildcard.counting.pem --key=c:\certs\_wildcard.counting-key.pem -n dev
kubectl create secret tls cfb-tls --cert=c:\certs\_wildcard.cfb.pem --key=c:\certs\_wildcard.cfb-key.pem -n dev
kubectl create secret tls hello-tls --cert=c:\certs\_wildcard.hello.pem --key=c:\certs\_wildcard.hello-key.pem -n dev
kubectl create secret tls ntest-tls --cert=c:\certs\_wildcard.ntest.pem --key=c:\certs\_wildcard.ntest-key.pem -n dev
kubectl create secret tls knfo-tls --cert=c:\certs\_wildcard.knfo.pem --key=c:\certs\_wildcard.knfo-key.pem -n dev


# Monitoring TLS (create namespace first since it will be auto-created later)
kubectl create namespace monitoring
kubectl create secret tls grafana-local-tls --cert=c:\certs\_wildcard.local+1.pem --key=c:\certs\_wildcard.local+1-key.pem -n monitoring

# 3. Install ArgoCD bootstrap manifests (stable release)
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 3.5 (OPTIONAL) Enable Helm version switching
# ============================================================================
# If you need a specific Helm version instead of the built-in one, follow these steps:
#
# Files needed (all in c:\code\argo-apps\argocd\bootstrap\):
#   - repo-server-helm-patch.yaml    (init container definition)
#   - kustomization.yaml              (applies the patch)
#   - argocd-cm-helm.yaml             (example ConfigMap settings)
#
# Step 1: Apply the init container patch to repo-server
kubectl apply -k c:\code\argo-apps\argocd\bootstrap\
#
# Step 2: Configure desired Helm version in argocd-cm (e.g., version 3.12.0)
kubectl patch configmap argocd-cm -n argocd -p '{"data":{"helm.version":"3.12.0"}}'
#
# Step 3: Restart repo-server (init container downloads and installs the version)
kubectl rollout restart deployment/argocd-repo-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
#
# To check which Helm version is active:
kubectl exec -it deployment/argocd-repo-server -n argocd -- helm version
#
# To change to a different Helm version later:
kubectl patch configmap argocd-cm -n argocd -p '{"data":{"helm.version":"3.13.3"}}'
kubectl rollout restart deployment/argocd-repo-server -n argocd
#
# To disable and use built-in Helm again:
kubectl patch configmap argocd-cm -n argocd --type json -p='[{"op": "remove", "path": "/data/helm.version"}]'
kubectl rollout restart deployment/argocd-repo-server -n argocd
#
# For more details, see: c:\code\argo-apps\argocd\bootstrap\HELM_VERSION_README.md
# ============================================================================

# 4. Create ArgoCD ingress
kubectl apply --server-side -f c:\code\argo-apps\argocd\bootstrap\argocd-ingress.yaml

# 4.5 Set up ArgoCD notifications (Slack)
# ============================================================================
# Secret name must be argocd-notifications-secret, key must be slack-api-url

kubectl apply -f c:\code\argo-apps\argocd\bootstrap\argocd-notifications-cm.yaml

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

Send-EventBridgeNotification "deploy done"

# ============================================================================
# ACCESS INSTRUCTIONS
# ============================================================================

# Access ArgoCD: https://argocd.local
# Access Counting App: https://dev.counting
# Access Grafana: https://grafana.local (user: admin, password: admin)

# Get ArgoCD admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "^-- Copy admin password above"
echo "ArgoCD URL: https://argocd.local"
echo "Counting App URL: https://dev.counting"
echo "Grafana URL: https://grafana.local"

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

