kubectl create namespace argocd

kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=8GZB5E2TGQeJdOOcSFRQz9KdY2BVGxwn -n argocd
kubectl create secret generic argocd-keycloak-ca --from-file=ca.crt="C:\code\keycloak\keycloak-root-ca.pem" -n argocd
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd

kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Install NGINX Gateway Fabric (prerequisite for Gateway API)
# Note: If this fails or seems complex, switch to traditional Ingress in applications/argocd-ingress.yaml
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install nginx-gateway nginx-stable/nginx-gateway -n nginx-gateway --create-namespace

# Apply root-app, which manages ArgoCD and all child applications via the app of apps pattern
#kubectl apply -f c:\code\argo-apps\argocd\root-app.yaml








kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
$ArgoPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 
setx ARGOCD_PASSWORD $ArgoPassword /M
$ArgoPassword 
$ArgoPassword | clip
