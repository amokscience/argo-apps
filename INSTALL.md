# ============================================================================
# ArgoCD Bootstrap Script - Complete Installation
# ============================================================================
# Run this entire script to bootstrap ArgoCD with Keycloak OIDC integration

# 1. Create namespace
kubectl create namespace argocd

# 2. Create secrets
kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=RyTihUdhH8ahTO6MIHJCkQ7DmolHlM3c -n argocd
kubectl label secret argocd-oidc-keycloak app.kubernetes.io/part-of=argocd -n argocd
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd

# 3. Install ArgoCD bootstrap manifests
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Install NGINX Ingress Controller
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install nginx-ingress nginx-stable/nginx-ingress -n nginx-ingress --create-namespace

# 5. Apply ArgoCD manifests from this repo
kubectl apply --server-side -f c:\code\argo-apps\argocd\applications\argocd-ingress.yaml
kubectl apply --server-side -f c:\code\argo-apps\argocd\applications\argocd-keycloak-oidc.yaml

# 6. Restart ArgoCD server to apply all configurations
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# ============================================================================
# ACCESS INSTRUCTIONS
# ============================================================================
# 1. Add to hosts file: 127.0.0.1 argocd.local
# 2. Access: http://argocd.local
# 3. Login with Keycloak SSO or use admin credentials:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo "^-- Copy admin password above"
echo "ArgoCD URL: http://argocd.local"



kubectl create secret tls counting-local-tls --cert=c:\certs\_wildcard.counting.local+1.pem --key=c:\certs\_wildcard.counting.local+1-key.pem -n dev


kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
$ArgoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 
setx ARGOCD_PASSWORD $ArgoPassword /M
$ArgoPassword 
$ArgoPassword | clip
