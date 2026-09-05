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
