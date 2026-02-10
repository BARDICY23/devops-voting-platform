SHELL := /bin/bash

KIND_CLUSTER ?= tqp

.PHONY: kind-up kind-down base-apply argocd-bootstrap helm-app-install helm-app-uninstall

kind-up:
	kind create cluster --name $(KIND_CLUSTER) --config scripts/kind-config.yaml || true

kind-down:
	kind delete cluster --name $(KIND_CLUSTER) || true

# Apply platform base (namespaces + PSA labels)
base-apply:
	kubectl apply -k platform/base

# Bootstrap ArgoCD (App of Apps)
# NOTE: ArgoCD itself must already be installed in the argocd namespace.
argocd-bootstrap:
	kubectl apply -f platform/argocd/bootstrap/app-of-apps.yaml

# Optional: install the app via Helm directly (without Argo)
helm-app-install:
	helm dependency update apps/helm/voting-app
	helm upgrade --install voting-app apps/helm/voting-app -n voting -f apps/helm/voting-app/values.yaml -f apps/helm/voting-app/values-dev.yaml

helm-app-uninstall:
	helm uninstall voting-app -n voting || true
