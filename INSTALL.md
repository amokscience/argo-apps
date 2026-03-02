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
# Allow Helm to adopt this secret (argo-cd chart also creates it; without these labels helm install fails)
kubectl label secret argocd-notifications-secret -n argocd app.kubernetes.io/managed-by=Helm
kubectl annotate secret argocd-notifications-secret -n argocd meta.helm.sh/release-name=argocd meta.helm.sh/release-namespace=argocd

# ArgoCD OIDC secret
kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=$env:KEYCLOAK_KEY -n argocd
kubectl label secret argocd-oidc-keycloak app.kubernetes.io/part-of=argocd -n argocd

# TLS certificates
kubectl create secret tls argocd-tls --cert=c:\certs\_wildcard.amok.pem --key=c:\certs\_wildcard.amok-key.pem -n argocd
kubectl create secret tls counting-tls --cert=c:\certs\_wildcard.counting.pem --key=c:\certs\_wildcard.counting-key.pem -n dev
kubectl create secret tls cfb-tls --cert=c:\certs\_wildcard.cfb.pem --key=c:\certs\_wildcard.cfb-key.pem -n dev
kubectl create secret tls hello-tls --cert=c:\certs\_wildcard.hello.pem --key=c:\certs\_wildcard.hello-key.pem -n dev
kubectl create secret tls ntest-tls --cert=c:\certs\_wildcard.ntest.pem --key=c:\certs\_wildcard.ntest-key.pem -n dev
kubectl create secret tls knfo-tls --cert=c:\certs\_wildcard.knfo.pem --key=c:\certs\_wildcard.knfo-key.pem -n dev

# Monitoring TLS (create namespace first since it will be auto-created later)
kubectl create secret tls grafana-tls --cert=c:\certs\_wildcard.amok.pem --key=c:\certs\_wildcard.amok-key.pem -n monitoring
kubectl create secret tls prometheus-tls --cert=c:\certs\_wildcard.amok.pem --key=c:\certs\_wildcard.amok-key.pem -n monitoring

# 3. Bootstrap ArgoCD via Helm (pinned version)
# ============================================================================
# Version is pinned here AND in argocd/applications/0-argocd-self-app.yaml. (chart 9.4.5 = ArgoCD v3.3.2)
# After step 5, ArgoCD manages its own Helm release via that Application —
# to upgrade ArgoCD later, only change targetRevision in 0-argocd-self-app.yaml.
helm repo add argo https://argoproj.github.io/argo-helm; helm repo update
helm install argocd argo/argo-cd --namespace argocd --create-namespace --version 9.4.5 --wait

# 3.5 (OPTIONAL) Enable Helm version switching for repo-server
# ============================================================================
# If you need a specific Helm version instead of the built-in one:
#
# Files needed (all in c:\code\argo-apps\argocd\bootstrap\):
#   - repo-server-helm-patch.yaml    (init container definition - version is the image tag)
#
# Step 1: Set desired version by updating the image tag in repo-server-helm-patch.yaml
#          e.g. image: alpine/helm:3.17.1  →  alpine/helm:3.18.0
# Step 2: Apply the strategic merge patch directly to the live Deployment
kubectl patch deployment argocd-repo-server -n argocd --patch-file c:\code\argo-apps\argocd\bootstrap\repo-server-helm-patch.yaml
#
# Step 3: Restart repo-server (init container copies helm binary from the image)
kubectl rollout restart deployment/argocd-repo-server -n argocd
kubectl rollout status deployment/argocd-repo-server -n argocd
#
# To check which Helm version is active (run after rollout completes):
kubectl exec -it deployment/argocd-repo-server -n argocd -- helm version
# To see init container logs:
kubectl logs deployment/argocd-repo-server -n argocd -c install-helm-version
#
# For more details, see: c:\code\argo-apps\argocd\bootstrap\HELM_VERSION_README.md
# ============================================================================

# 4. Deploy root application (scaffolds all applications including ArgoCD self-management)
# ============================================================================
# NOTE: 0-argocd-self-app.yaml (wave 0) will have ArgoCD adopt its own Helm release.
#       All ArgoCD config (OIDC, ingress, params, RBAC, notifications) is in that file's values block.
#       Future ArgoCD upgrades: change targetRevision in 0-argocd-self-app.yaml and push.
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

# Access ArgoCD: https://argocd.amok
# Access Counting App: https://dev.counting
# Access Grafana: https://grafana.amok (user: admin, password: admin)

# Get ArgoCD admin password:
$ArgoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
argocd login argocd.amok --username admin --password $ArgoPassword --insecure --grpc-web


# ============================================================================
# RBAC MANAGEMENT (GitOps)
# ============================================================================
# RBAC policies are managed via Helm values in argocd/applications/0-argocd-self-app.yaml
# under configs.rbac.policy.csv — the argo-cd Helm chart owns argocd-rbac-cm.
#
# To update RBAC policies:
# 1. Edit the policy.csv block in 0-argocd-self-app.yaml
# 2. Commit and push changes
# 3. ArgoCD will auto-sync (helm upgrade) and apply the new RBAC

