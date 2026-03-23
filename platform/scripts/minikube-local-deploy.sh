#!/usr/bin/env bash
set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-minikube}"
NAMESPACE="${KUBE_NAMESPACE:-voting}"
RELEASE="${HELM_RELEASE:-voting-app}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART_DIR="${ROOT_DIR}/platform/apps/helm/voting-app"
VALUES_FILE="${CHART_DIR}/values-local.yaml"
NODE=""
RUNTIME_VERSION=""
RUNTIME=""

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

build_image() {
  local image="$1"
  local context_dir="$2"

  echo "==> Building ${image} from ${context_dir}"
  docker build -t "${image}" "${ROOT_DIR}/${context_dir}"
}

load_image() {
  local image="$1"
  local tar_name
  local tar_path

  tar_name="$(echo "${image}" | tr '/:' '_').tar"
  tar_path="/tmp/${tar_name}"

  echo "==> Exporting ${image}"
  docker save -o "${tar_path}" "${image}"

  echo "==> Copying ${tar_name} into profile ${PROFILE}"
  minikube -p "${PROFILE}" cp "${tar_path}" "/tmp/${tar_name}"

  case "${RUNTIME}" in
    docker)
      echo "==> Loading ${image} into Docker runtime inside Minikube"
      minikube -p "${PROFILE}" ssh -- "docker load -i /tmp/${tar_name}; sudo rm -f /tmp/${tar_name} || true"
      minikube -p "${PROFILE}" ssh -- "docker image inspect '${image}' >/dev/null"
      ;;
    containerd)
      echo "==> Loading ${image} into containerd runtime inside Minikube"
      minikube -p "${PROFILE}" ssh -- "sudo ctr -n k8s.io images import /tmp/${tar_name}; sudo rm -f /tmp/${tar_name} || true"
      minikube -p "${PROFILE}" ssh -- "sudo ctr -n k8s.io images ls | awk '{print \$1}' | grep -Fx '${image}' >/dev/null"
      ;;
    cri-o)
      echo "==> Loading ${image} into CRI-O runtime inside Minikube"
      minikube -p "$PROFILE" ssh -- "docker load -i /tmp/${tar_name}; sudo rm -f /tmp/${tar_name} || true"
      minikube -p "${PROFILE}" ssh -- "sudo podman image exists '${image}'"
      ;;
    *)
      echo "Unsupported container runtime: ${RUNTIME_VERSION}" >&2
      exit 1
      ;;
  esac

  rm -f "${tar_path}"
}

require docker
require kubectl
require helm
require minikube

# Avoid accidentally talking to a stale minikube docker-env from another profile.
unset DOCKER_TLS_VERIFY DOCKER_HOST DOCKER_CERT_PATH MINIKUBE_ACTIVE_DOCKERD

if ! minikube -p "${PROFILE}" status >/dev/null 2>&1; then
  echo "Minikube profile '${PROFILE}' is not running." >&2
  echo "Hint: start it with something like: minikube start -p ${PROFILE}" >&2
  exit 1
fi

echo "==> Forcing kubectl context to ${PROFILE}"
kubectl config use-context "${PROFILE}" >/dev/null

echo "==> Confirming active context"
kubectl config current-context

NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
RUNTIME_VERSION="$(kubectl get node "${NODE}" -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}')"
RUNTIME="${RUNTIME_VERSION%%:*}"

echo "==> Active Minikube profile: ${PROFILE}"
echo "==> Kubernetes node: ${NODE}"
echo "==> Container runtime: ${RUNTIME_VERSION}"

build_image "docker.io/library/platform-vote:latest" "services/vote"
build_image "docker.io/library/platform-result:latest" "services/result"
build_image "docker.io/library/platform-worker:latest" "services/worker"

load_image "docker.io/library/platform-vote:latest"
load_image "docker.io/library/platform-result:latest"
load_image "docker.io/library/platform-worker:latest"

if [[ -f "${CHART_DIR}/charts/postgresql-15.5.20.tgz" && -f "${CHART_DIR}/charts/redis-19.6.4.tgz" ]]; then
  echo "==> Using vendored chart dependencies from ${CHART_DIR}/charts"
else
  echo "==> Chart archives missing, rebuilding dependencies"
  helm dependency build "${CHART_DIR}"
fi

echo "==> Deploying ${RELEASE} into namespace ${NAMESPACE}"
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}" \
  --wait \
  --wait-for-jobs \
  --timeout 10m

echo "==> Release status"
helm -n "${NAMESPACE}" status "${RELEASE}"

echo "==> Pods"
kubectl -n "${NAMESPACE}" get pods -o wide

cat <<'EOF'

Next checks:
  kubectl -n voting port-forward svc/vote 8080:80
  kubectl -n voting port-forward svc/result 8081:80
  kubectl -n voting exec -it voting-app-redis-master-0 -- redis-cli LRANGE votes 0 5
  kubectl -n voting logs deploy/worker --tail=120
  kubectl -n voting exec -it voting-app-postgresql-0 -- bash -lc 'PGPASSWORD=postgres psql -U voting -d votes -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"'
EOF
