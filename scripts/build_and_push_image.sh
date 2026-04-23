#!/bin/bash

set -euo pipefail

PROJECT="${PROJECT:-ares}"
IMAGE="${IMAGE:-spring-boot-hello-k8s}"
QUADRA_REPO="${QUADRA_REPO:-registry.strln.net}"
REPO="${PROJECT}/${IMAGE}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-776389595347}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-ares-stage}"
AWS_REGION_NAME="${AWS_REGION_NAME:-us-west-2}"
DOCKER_BUILD_LOG_FILE="${DOCKER_BUILD_LOG_FILE:-docker_build.log}"
SKIP_QUADRA_PUSH="${SKIP_QUADRA_PUSH:-false}"

BUILD_TAG="${1:-}"

if [[ -z "${BUILD_TAG}" ]]; then
  echo "Usage: $0 <build-tag>" >&2
  exit 1
fi

echo "Building Docker image ${REPO}:${BUILD_TAG}"
docker build --build-arg CACHEBUST="$(date +%s)" -t "${REPO}" . > "${DOCKER_BUILD_LOG_FILE}" 2>&1 || {
  echo "Docker build failed. See ${DOCKER_BUILD_LOG_FILE} for details." >&2
  cat "${DOCKER_BUILD_LOG_FILE}" >&2
  exit 1
}

echo "Tagging image for Quadra registry"
docker tag "${REPO}" "${QUADRA_REPO}/${REPO}:${BUILD_TAG}"
if [[ "${BUILD_TAG}" == "master" ]]; then
  docker tag "${REPO}" "${QUADRA_REPO}/${REPO}:latest"
fi

if [[ "${SKIP_QUADRA_PUSH}" == "true" ]]; then
  echo "Skipping Quadra push because SKIP_QUADRA_PUSH=true"
else
  echo "Pushing Docker image to Quadra registry"
  docker push "${QUADRA_REPO}/${REPO}:${BUILD_TAG}"
  if [[ "${BUILD_TAG}" == "master" ]]; then
    docker push "${QUADRA_REPO}/${REPO}:latest"
  fi
fi

echo "Logging in to AWS ECR"
aws --profile "${AWS_PROFILE_NAME}" ecr get-login-password --region "${AWS_REGION_NAME}" | \
  docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION_NAME}.amazonaws.com"

echo "Tagging image for AWS ECR"
SOURCE_IMAGE="${REPO}"
if [[ "${SKIP_QUADRA_PUSH}" != "true" ]]; then
  SOURCE_IMAGE="${QUADRA_REPO}/${REPO}:${BUILD_TAG}"
fi

docker tag "${SOURCE_IMAGE}" \
  "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION_NAME}.amazonaws.com/${PROJECT}/${IMAGE}:${BUILD_TAG}"

echo "Pushing Docker image to AWS ECR"
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION_NAME}.amazonaws.com/${PROJECT}/${IMAGE}:${BUILD_TAG}"

echo "Done"
echo "Quadra image: ${QUADRA_REPO}/${REPO}:${BUILD_TAG}"
echo "ECR image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION_NAME}.amazonaws.com/${PROJECT}/${IMAGE}:${BUILD_TAG}"
