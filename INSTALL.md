kubectl create namespace argocd

kubectl create secret generic argocd-oidc-keycloak --from-literal=client-secret=$keycloakSecret -n argocd
kubectl create secret generic argocd-keycloak-ca --from-file=ca.crt="C:\code\keycloak\keycloak-root-ca.pem" -n argocd
kubectl create secret tls argocd-tls --cert=c:\code\argocd.crt --key=c:\code\argocd.key -n argocd

kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Apply root-app, which manages ArgoCD and all child applications via the app of apps pattern
kubectl apply -f c:\code\argo-apps\argocd\root-app.yaml
