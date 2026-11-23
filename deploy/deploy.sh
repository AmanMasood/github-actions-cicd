#!/usr/bin/env bash
# Pull an image and (re)start the container on a Linux host.
# Usage: deploy.sh <image:tag> <environment>
set -euo pipefail

IMAGE="${1:?image:tag required}"
ENVIRONMENT="${2:?environment required (staging|production)}"
NAME="release-info-${ENVIRONMENT}"
ENV_FILE="/opt/release-info/${ENVIRONMENT}.env"

source "${ENV_FILE}"
echo "Deploying ${IMAGE} to ${ENVIRONMENT} on port ${HOST_PORT}"

docker pull "${IMAGE}"
PREVIOUS="$(docker inspect --format '{{.Config.Image}}' "${NAME}" 2>/dev/null || true)"

docker rm -f "${NAME}" >/dev/null 2>&1 || true
docker run -d --name "${NAME}" --restart unless-stopped \
  --env-file "${ENV_FILE}" -p "${HOST_PORT}:8000" "${IMAGE}"

for i in $(seq 1 20); do
  if curl -fsS "http://127.0.0.1:${HOST_PORT}/health" >/dev/null; then
    echo "Healthy after ${i} checks"; exit 0
  fi
  sleep 2
done

echo "Health check failed, rolling back to ${PREVIOUS:-nothing}" >&2
docker rm -f "${NAME}" || true
if [[ -n "${PREVIOUS}" ]]; then
  docker run -d --name "${NAME}" --restart unless-stopped \
    --env-file "${ENV_FILE}" -p "${HOST_PORT}:8000" "${PREVIOUS}"
fi
exit 1
