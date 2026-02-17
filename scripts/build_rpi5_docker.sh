#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-flowstate-rpi5-builder:latest}"
PLATFORM="${PLATFORM:-linux/arm64}"
JOBS="${JOBS:-2}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required."
  exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
  echo "docker buildx is required."
  exit 1
fi

cd "${ROOT_DIR}"

echo "Building Docker image ${IMAGE_NAME} for ${PLATFORM}..."
docker buildx build \
  --platform "${PLATFORM}" \
  -f docker/Dockerfile.rpi5-build \
  -t "${IMAGE_NAME}" \
  --load \
  .

echo "Running UPBGE build inside container..."
docker run --rm \
  --platform "${PLATFORM}" \
  -e LANG=C.UTF-8 \
  -e LC_ALL=C.UTF-8 \
  -e SKIP_APT=1 \
  -e USE_SOURCE_DEPS=1 \
  -e JOBS="${JOBS}" \
  -e UPBGE_DIR=/work/third_party/upbge \
  -v "${ROOT_DIR}:/work" \
  "${IMAGE_NAME}" \
  /bin/bash -lc "./scripts/setup_rpi5.sh"

echo "Containerized build finished."
echo "Expected binary: ${ROOT_DIR}/third_party/upbge/build_linux/bin/blender"
