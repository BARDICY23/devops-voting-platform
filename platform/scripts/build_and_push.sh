#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-your-org}"
TAG="${TAG:-latest}"

build() {
  local name="$1"
  docker build -t "${REGISTRY}/${OWNER}/${name}:${TAG}" "services/${name}"
}

push() {
  local name="$1"
  docker push "${REGISTRY}/${OWNER}/${name}:${TAG}"
}

for svc in vote result worker seed-data; do
  build "${svc}"
  push "${svc}"
done
