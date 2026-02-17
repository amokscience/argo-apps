# ============================================================================
# HELM VERSION CONFIGURATION
# ============================================================================
# 
# For the init container to work, add this to argocd-cm ConfigMap:
#
#   helm.version: "3.12.0"    # Use this version
#   helm.version: "3.13.3"    # Or any other version
#
# To disable (use built-in Helm):
#   - Remove the helm.version line entirely
#   - OR comment it out
#
# When you change helm.version, restart repo-server pods:
#   kubectl rollout restart deployment/argocd-repo-server -n argocd
#
# ============================================================================
# IMPLEMENTATION NOTES
# ============================================================================
#
# The init container (repo-server-helm-patch.yaml):
# 1. Checks for HELM_VERSION environment variable (from argocd-cm)
# 2. If NOT set → skips, uses built-in Helm (backward compatible)
# 3. If set → downloads that version and replaces /usr/local/bin/helm
# 4. Uses emptyDir volume so replacement is pod-local (no persistence needed)
#
# ============================================================================
