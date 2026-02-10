kubectl create namespace argocd

kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=8GZB5E2TGQeJdOOcSFRQz9KdY2BVGxwn -n argocd
kubectl create secret generic argocd-keycloak-ca --from-file=ca.crt="C:\code\keycloak\keycloak-root-ca.pem" -n argocd
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd

kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Install NGINX Ingress Controller
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install nginx-ingress nginx-stable/nginx-ingress -n nginx-ingress --create-namespace

# Apply ArgoCD Ingress (manual)
kubectl apply -f c:\code\argo-apps\argocd\applications\argocd-ingress.yaml

# ============================================================================
# GET CREDENTIALS & ACCESS
# ============================================================================
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access: http://argocd.local
# Add to hosts file: 127.0.0.1 argocd.local
# Login: admin / <password from command above>





kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
$ArgoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 
setx ARGOCD_PASSWORD $ArgoPassword /M
$ArgoPassword 
$ArgoPassword | clip
