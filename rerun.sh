#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./rerun.sh vX.Y.Z [-- <extra docker run args...>]

Environment variables:
  IMAGE           Docker image repo (default: ghcr.io/zwenooo/sub-store)
  CONTAINER_NAME  Container name      (default: sub-store)
  HOST_PORT       Host port           (default: 3000)
  DATA_PATH       Volume/path mount   (default: sub-store-data)

Examples:
  ./rerun.sh v2.21.3
  HOST_PORT=8080 ./rerun.sh v2.21.3
  ./rerun.sh v2.21.3 -- -e SUB_STORE_BODY_JSON_LIMIT=10mb
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || ${1:-} == "" ]]; then
  usage
  exit 1
fi

TAG="$1"
shift

if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: tag must match vX.Y.Z, got: $TAG" >&2
  exit 1
fi

if [[ ${1:-} == "--" ]]; then
  shift
fi

IMAGE="${IMAGE:-ghcr.io/zwenooo/sub-store}"
CONTAINER_NAME="${CONTAINER_NAME:-sub-store}"
HOST_PORT="${HOST_PORT:-3000}"
DATA_PATH="${DATA_PATH:-sub-store-data}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is not installed or not in PATH" >&2
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  docker rm -f "$CONTAINER_NAME"
fi

docker pull "${IMAGE}:${TAG}"

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "${HOST_PORT}:3000" \
  -v "${DATA_PATH}:/data" \
  "$@" \
  "${IMAGE}:${TAG}"

docker ps --filter "name=^/${CONTAINER_NAME}$"
