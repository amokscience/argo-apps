# ============================================================================
# HELM VERSION CONFIGURATION
# ============================================================================
# 
# The desired Helm version is pinned via the init container image tag in
# repo-server-helm-patch.yaml:
#
#   image: alpine/helm:3.17.1    # Change this tag to switch versions
#
# The init container copies /usr/bin/helm from that image into an emptyDir
# volume, which is then subPath-mounted over /usr/local/bin/helm in the
# argocd-repo-server container. All other image binaries are untouched.
#
# To change the Helm version:
# 1. Update the image tag in repo-server-helm-patch.yaml
# 2. Apply the patch: kubectl patch deployment argocd-repo-server -n argocd --patch-file argocd/bootstrap/repo-server-helm-patch.yaml
# 3. Restart: kubectl rollout restart deployment/argocd-repo-server -n argocd
# 4. Verify (after rollout completes): kubectl exec -it deployment/argocd-repo-server -n argocd -- helm version
#
# NOTE: helm.version is NOT a native ArgoCD property. Do not add it to argocd-cm.
# NOTE: This approach is derived from the official ArgoCD Helm plugin docs:
#       https://argo-cd.readthedocs.io/en/stable/user-guide/helm/#using-initcontainers
