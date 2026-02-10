kubectl create namespace argocd

kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=8GZB5E2TGQeJdOOcSFRQz9KdY2BVGxwn -n argocd
kubectl create secret generic argocd-keycloak-ca --from-file=ca.crt="C:\code\keycloak\keycloak-root-ca.pem" -n argocd
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd

kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Install NGINX Ingress Controller (required for argocd-ingress.yaml to work)
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install nginx-ingress nginx-stable/nginx-ingress -n nginx-ingress --create-namespace

# Apply root-app, which manages ArgoCD and all child applications via the app of apps pattern
kubectl apply -f c:\code\argo-apps\argocd\root-app.yaml

# ============================================================================
# TESTING COMMANDS - Run these to verify everything is working
# ============================================================================
# Check NGINX Ingress Controller
kubectl get pods -n nginx-ingress
kubectl get svc -n nginx-ingress

# Check ArgoCD deployment
kubectl get pods -n argocd
kubectl get application -n argocd

# Check Ingress
kubectl get ingress -n argocd
kubectl describe ingress argocd-server -n argocd

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-server --tail=20
kubectl logs -n argocd deployment/argocd-application-controller --tail=20

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# List ArgoCD applications
kubectl get applications -n argocd





kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
$ArgoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 
setx ARGOCD_PASSWORD $ArgoPassword /M
$ArgoPassword 
$ArgoPassword | clip
