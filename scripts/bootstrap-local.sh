#!/usr/bin/env bash
set -euo pipefail

# Bootstraps the dummy AWS credentials Secret that ESO's local ClusterSecretStore
# authenticates with against `floci`. This is a one-time, imperative step
# deliberately kept outside ArgoCD's declarative sync scope — it's what ESO itself
# needs before it can sync anything else, so it can't be provisioned by ESO/ArgoCD
# in the usual way.
#
# Safe to re-run: idempotent via `kubectl apply`.

NAMESPACE="${NAMESPACE:-external-secrets}"
SECRET_NAME="${SECRET_NAME:-floci-aws-dummy-creds}"
KUBE_CONTEXT="${KUBE_CONTEXT:-floci-url-shortener}"

echo "Target context:   ${KUBE_CONTEXT}"
echo "Target namespace: ${NAMESPACE}"
echo "Secret name:      ${SECRET_NAME}"
echo

kubectl --context "${KUBE_CONTEXT}" create namespace "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl --context "${KUBE_CONTEXT}" apply -f -

kubectl --context "${KUBE_CONTEXT}" -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" \
  --from-literal=access-key-id=test \
  --from-literal=secret-access-key=test \
  --dry-run=client -o yaml | kubectl --context "${KUBE_CONTEXT}" apply -f -

echo
echo "Done. Secret '${SECRET_NAME}' is present in namespace '${NAMESPACE}'."

EKS_CONTAINER="${EKS_CONTAINER:-floci-eks-url-shortener-local}"
REGISTRY_HOST="${REGISTRY_HOST:-floci-ecr-registry:5000}"
REGISTRY_HOST_FIX="${REGISTRY_HOST_FIX:-host.docker.internal:5100}"

echo
echo "Patching containerd registry mirror config in '${EKS_CONTAINER}'..."
echo "(floci-ecr-registry doesn't resolve on Docker's default bridge network from"
echo " inside the k3s container; host.docker.internal does.)"

docker exec "${EKS_CONTAINER}" sh -c "
  sed -i 's#http://${REGISTRY_HOST}#http://${REGISTRY_HOST_FIX}#g' /etc/rancher/k3s/registries.yaml
  grep -rl '${REGISTRY_HOST}' /var/lib/rancher/k3s/agent/etc/containerd/certs.d/ 2>/dev/null | \
    xargs -r sed -i 's#${REGISTRY_HOST}#${REGISTRY_HOST_FIX}#g'
"

echo "Done. Local image push/pull via localhost:5100 should now resolve correctly."
