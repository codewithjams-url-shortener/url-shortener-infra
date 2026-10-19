#!/usr/bin/env bash
set -euo pipefail

# Verifies a config publish and canary rollout end to end, the way the `publishAppConfig` pipeline step does it
# (ADR-0011): finds the service's AppConfig Application, Environment and `runtime-settings` Profile by name, publishes
# a config file as a new hosted configuration version, and starts a deployment of it with the predefined
# AppConfig.Canary10Percent20Minutes strategy. With ROLLBACK_TEST=true it then forces the service's 5xx-rate CloudWatch
# alarm into ALARM and checks that AppConfig rolls the deployment back.
#
# The AppConfig resources and the alarm come from the `appconfig` and `cloudwatch-alarm` Terraform modules, so apply
# those first. This script mirrors the step's AWS commands; it does not run the Jenkins pipeline itself.
#
# Against floci (the default) the publish and the deployment can be checked, but not the canary or the rollback:
# floci completes a deployment instantly with none of the strategy's parameters, drops an Environment's alarm monitor,
# and never evaluates an alarm. ROLLBACK_TEST=true therefore fails there by design, which is what shows the check does
# not pass vacuously; the rollback can only be verified against real AWS, with AWS_ENDPOINT_URL set to an empty string.
#
# Each run publishes a new hosted version and starts a deployment, even for an unchanged config.
#
# Usage:
#   SERVICE=url-service CONFIG_FILE=../url-service-config/environments/local/config.json \
#     scripts/verify-config-rollout.sh
#   SERVICE=url-service CONFIG_FILE=... AWS_ENDPOINT_URL= ENVIRONMENT=aws ROLLBACK_TEST=true \
#     scripts/verify-config-rollout.sh
#
# Settings (environment variables):
#   SERVICE                   (required) The service: the AppConfig Application's name.
#   CONFIG_FILE               (required) The config to publish, e.g. a config repo's environments/<env>/config.json.
#   ENVIRONMENT               The AppConfig Environment. Default "local".
#   AWS_ENDPOINT_URL          The AWS API endpoint. Default http://localhost:4566 (floci). Set it to an empty string for
#                             the real AWS endpoints.
#   AWS_REGION                Default us-west-2.
#   ALARM_NAME                The alarm that guards the deployment. Default "<SERVICE>-5xx-rate".
#   ROLLBACK_TEST             "true" to also fire the alarm and expect a rollback. Default "false".
#   ACTIVE_TIMEOUT_SECONDS    How long to wait for the deployment to be in progress before firing the alarm. Default 120.
#   ROLLBACK_TIMEOUT_SECONDS  How long to wait for the rollback after firing the alarm. Default 600.

SERVICE="${SERVICE:?SERVICE is required, e.g. SERVICE=url-service}"
CONFIG_FILE="${CONFIG_FILE:?CONFIG_FILE is required, e.g. CONFIG_FILE=../url-service-config/environments/local/config.json}"
ENVIRONMENT="${ENVIRONMENT:-local}"
AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL-http://localhost:4566}"
AWS_REGION="${AWS_REGION:-us-west-2}"
ALARM_NAME="${ALARM_NAME:-${SERVICE}-5xx-rate}"
ROLLBACK_TEST="${ROLLBACK_TEST:-false}"
ACTIVE_TIMEOUT_SECONDS="${ACTIVE_TIMEOUT_SECONDS:-120}"
ROLLBACK_TIMEOUT_SECONDS="${ROLLBACK_TIMEOUT_SECONDS:-600}"

PROFILE_NAME="runtime-settings"
STRATEGY_ID="AppConfig.Canary10Percent20Minutes"

export AWS_DEFAULT_REGION="${AWS_REGION}"
if [[ -n "${AWS_ENDPOINT_URL}" ]]; then
  export AWS_ENDPOINT_URL
  TARGET="${AWS_ENDPOINT_URL} (not real AWS)"
else
  unset AWS_ENDPOINT_URL
  TARGET="real AWS"
fi

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*"
}

# Only the real AWS can be held to what the rollback needs; against an endpoint override the gap is reported instead.
strict_or_warn() {
  if [[ -z "${AWS_ENDPOINT_URL}" ]]; then
    fail "$*"
  else
    warn "$* (tolerated against ${AWS_ENDPOINT_URL}, which is not real AWS)"
  fi
}

lookup() {
  local description="$1"
  shift
  local id
  # A failed AWS call (no credentials, the endpoint down) must not be reported as the resource being absent: errexit
  # does not reach inside a command substitution, so the status is checked here, with the CLI's own error shown above.
  if ! id="$("$@" --output text)"; then
    fail "could not look up ${description}: the AWS CLI call above failed"
  fi
  if [[ -z "${id}" || "${id}" == "None" ]]; then
    fail "${description} was not found; apply the appconfig Terraform module first"
  fi
  echo "${id}"
}

deployment_state() {
  aws appconfig get-deployment --application-id "${APP_ID}" --environment-id "${ENV_ID}" \
    --deployment-number "$1" --query State --output text
}

echo "Target:       ${TARGET}"
echo "Service:      ${SERVICE}"
echo "Environment:  ${ENVIRONMENT}"
echo "Config file:  ${CONFIG_FILE}"
echo "Alarm:        ${ALARM_NAME}"
echo "Rollback test: ${ROLLBACK_TEST}"
echo

[[ -f "${CONFIG_FILE}" ]] || fail "${CONFIG_FILE} does not exist"
python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "${CONFIG_FILE}" 2>/dev/null \
  || fail "${CONFIG_FILE} is not valid JSON"

echo "1. Finding the AppConfig resources by name"
APP_ID="$(lookup "AppConfig application '${SERVICE}'" aws appconfig list-applications \
  --query "Items[?Name=='${SERVICE}'].Id | [0]")"
ENV_ID="$(lookup "AppConfig environment '${ENVIRONMENT}' of '${SERVICE}'" aws appconfig list-environments \
  --application-id "${APP_ID}" --query "Items[?Name=='${ENVIRONMENT}'].Id | [0]")"
PROFILE_ID="$(lookup "AppConfig configuration profile '${PROFILE_NAME}' of '${SERVICE}'" \
  aws appconfig list-configuration-profiles --application-id "${APP_ID}" \
  --query "Items[?Name=='${PROFILE_NAME}'].Id | [0]")"
echo "   application ${APP_ID}, environment ${ENV_ID}, profile ${PROFILE_ID}"

echo "2. Checking the environment is wired to the alarm"
ALARM_ARN="$(aws cloudwatch describe-alarms --alarm-names "${ALARM_NAME}" \
  --query 'MetricAlarms[0].AlarmArn' --output text 2>/dev/null || true)"
if [[ -z "${ALARM_ARN}" || "${ALARM_ARN}" == "None" ]]; then
  strict_or_warn "alarm '${ALARM_NAME}' does not exist; apply the cloudwatch-alarm Terraform module first"
else
  MONITORED_ARN="$(aws appconfig get-environment --application-id "${APP_ID}" --environment-id "${ENV_ID}" \
    --query 'Monitors[0].AlarmArn' --output text)"
  if [[ "${MONITORED_ARN}" == "${ALARM_ARN}" ]]; then
    echo "   the environment monitors ${ALARM_ARN}"
  else
    strict_or_warn "the environment does not monitor ${ALARM_ARN} (monitors: ${MONITORED_ARN}), so no rollback can fire"
  fi
fi

echo "3. Publishing ${CONFIG_FILE} as a new hosted configuration version"
VERSION="$(aws appconfig create-hosted-configuration-version --application-id "${APP_ID}" \
  --configuration-profile-id "${PROFILE_ID}" --content-type application/json \
  --description "rollout verification" --content "fileb://${CONFIG_FILE}" /dev/null \
  --query VersionNumber --output text)"
STORED="$(mktemp)"
trap 'rm -f "${STORED}"' EXIT
aws appconfig get-hosted-configuration-version --application-id "${APP_ID}" \
  --configuration-profile-id "${PROFILE_ID}" --version-number "${VERSION}" "${STORED}" >/dev/null
cmp -s "${STORED}" "${CONFIG_FILE}" || fail "hosted version ${VERSION} does not hold the published content"
echo "   hosted version ${VERSION}, and its stored content matches the file"

echo "4. Starting the canary deployment"
DEPLOYMENT="$(aws appconfig start-deployment --application-id "${APP_ID}" --environment-id "${ENV_ID}" \
  --configuration-profile-id "${PROFILE_ID}" --configuration-version "${VERSION}" \
  --deployment-strategy-id "${STRATEGY_ID}" --description "rollout verification" \
  --query DeploymentNumber --output text)"
STARTED_WITH="$(aws appconfig get-deployment --application-id "${APP_ID}" --environment-id "${ENV_ID}" \
  --deployment-number "${DEPLOYMENT}" --query 'DeploymentStrategyId' --output text)"
[[ "${STARTED_WITH}" == "${STRATEGY_ID}" ]] \
  || fail "deployment ${DEPLOYMENT} used strategy '${STARTED_WITH}', not ${STRATEGY_ID}"
STATE="$(deployment_state "${DEPLOYMENT}")"
echo "   deployment ${DEPLOYMENT} of version ${VERSION} with ${STRATEGY_ID}, state ${STATE}"
GROWTH="$(aws appconfig get-deployment --application-id "${APP_ID}" --environment-id "${ENV_ID}" \
  --deployment-number "${DEPLOYMENT}" \
  --query '[GrowthFactor,DeploymentDurationInMinutes,FinalBakeTimeInMinutes]' --output text)"
if [[ "${GROWTH}" == *None* ]]; then
  strict_or_warn "the deployment reports no canary parameters (growth factor, duration, bake time): '${GROWTH}'"
else
  echo "   growth factor, duration and bake time (minutes): ${GROWTH}"
fi

if [[ "${ROLLBACK_TEST}" != "true" ]]; then
  echo
  echo "Done: published and deployed. Rollback was not tested (ROLLBACK_TEST is not true)."
  exit 0
fi

echo "5. Rollback: waiting for the deployment to be in progress"
fire_deadline=$((SECONDS + ACTIVE_TIMEOUT_SECONDS))
until [[ "${STATE}" == "DEPLOYING" || "${STATE}" == "BAKING" ]]; do
  case "${STATE}" in
    COMPLETE | ROLLED_BACK | REVERTED)
      fail "deployment ${DEPLOYMENT} is already ${STATE}, so there is nothing left to roll back; the alarm cannot be tested against it"
      ;;
  esac
  ((SECONDS < fire_deadline)) || fail "deployment ${DEPLOYMENT} was still ${STATE} after ${ACTIVE_TIMEOUT_SECONDS}s"
  sleep 5
  STATE="$(deployment_state "${DEPLOYMENT}")"
done
echo "   deployment ${DEPLOYMENT} is ${STATE}"

# However this ends, leave the alarm as it would normally be rather than stuck in ALARM.
restore_alarm() {
  aws cloudwatch set-alarm-state --alarm-name "${ALARM_NAME}" --state-value OK \
    --state-reason "rollout verification finished" >/dev/null 2>&1 || true
}
trap 'rm -f "${STORED}"; restore_alarm' EXIT

echo "6. Forcing ${ALARM_NAME} into ALARM, as a 5xx spike would"
aws cloudwatch set-alarm-state --alarm-name "${ALARM_NAME}" --state-value ALARM \
  --state-reason "rollout verification: simulated 5xx spike"
rollback_deadline=$((SECONDS + ROLLBACK_TIMEOUT_SECONDS))
until [[ "${STATE}" == "ROLLED_BACK" ]]; do
  ((SECONDS < rollback_deadline)) \
    || fail "deployment ${DEPLOYMENT} was still ${STATE} ${ROLLBACK_TIMEOUT_SECONDS}s after the alarm fired; it was not rolled back"
  sleep 10
  STATE="$(deployment_state "${DEPLOYMENT}")"
  echo "   deployment ${DEPLOYMENT}: ${STATE}"
done

echo
echo "Done: published, deployed, and rolled back by the alarm."
