# ============================================================================
# HELM VERSION CONFIGURATION
# ============================================================================
# 
# The desired Helm version is hardcoded in repo-server-helm-patch.yaml:
#
#   HELM_VERSION="3.17.1"    # Change this value to switch versions
#
# To change the Helm version:
# 1. Edit HELM_VERSION in repo-server-helm-patch.yaml
# 2. Apply the patch: kubectl apply -k argocd/bootstrap/
# 3. Restart: kubectl rollout restart deployment/argocd-repo-server -n argocd
# 4. Verify: kubectl exec -it deployment/argocd-repo-server -n argocd -- helm version
#
# NOTE: helm.version is NOT a native ArgoCD property. Do not add it to argocd-cm.
#
# ============================================================================
# IMPLEMENTATION NOTES
# ============================================================================
#
# The init container (repo-server-helm-patch.yaml):
# 1. Downloads the specified Helm version from get.helm.sh
# 2. Writes it to an emptyDir volume at /helm-override/helm
# 3. The main argocd-repo-server container mounts that file via subPath
#    over /usr/local/bin/helm ONLY - all other image binaries are untouched
#
# ============================================================================
