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

EKS_CONTAINER="${EKS_CONTAINER:-floci-url-shortener-eks-url-shortener-local}"
REGISTRY_HOST="${REGISTRY_HOST:-floci-url-shortener-ecr-registry:5000}"
REGISTRY_HOST_FIX="${REGISTRY_HOST_FIX:-host.docker.internal:5100}"
REGISTRIES_YAML="/etc/rancher/k3s/registries.yaml"

echo
echo "Patching containerd registry mirror config in '${EKS_CONTAINER}'..."
echo "(floci-ecr-registry doesn't resolve on Docker's default bridge network from"
echo " inside the k3s container; host.docker.internal does.)"

# floci derives its sibling container names itself and has changed them between versions, so
# distinguish "wrong container name" from "container has no registry config" below.
if ! docker inspect "${EKS_CONTAINER}" >/dev/null 2>&1; then
  echo "ERROR: container '${EKS_CONTAINER}' not found. Running containers with 'eks' in the name:" >&2
  docker ps --filter "name=eks" --format '  {{.Names}}' >&2
  echo "Re-run with EKS_CONTAINER=<name> if one of those is the k3s container." >&2
  exit 1
fi

# Without this check the sed below fails with "No such file" but the surrounding shell command
# still exits 0, so the script would go on to claim success.
if ! docker exec "${EKS_CONTAINER}" test -f "${REGISTRIES_YAML}"; then
  echo "ERROR: ${REGISTRIES_YAML} does not exist in '${EKS_CONTAINER}', so there is no registry mirror" >&2
  echo "config to patch. Either this floci version no longer writes one and this step is obsolete," >&2
  echo "or the cluster was created without it and image pulls from localhost:5100 will fail." >&2
  exit 1
fi

docker exec "${EKS_CONTAINER}" sh -c "
  sed -i 's#http://${REGISTRY_HOST}#http://${REGISTRY_HOST_FIX}#g' /etc/rancher/k3s/registries.yaml
  grep -rl '${REGISTRY_HOST}' /var/lib/rancher/k3s/agent/etc/containerd/certs.d/ 2>/dev/null | \
    xargs -r sed -i 's#${REGISTRY_HOST}#${REGISTRY_HOST_FIX}#g'
"

echo "Done. Local image push/pull via localhost:5100 should now resolve correctly."
