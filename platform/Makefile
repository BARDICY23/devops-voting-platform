SHELL := /bin/bash

KIND_CLUSTER ?= tqp
MINIKUBE_PROFILE ?= minikube
KUBE_NAMESPACE ?= voting
HELM_RELEASE ?= voting-app

.PHONY: kind-up kind-down base-apply argocd-bootstrap helm-app-install helm-app-uninstall minikube-local-deploy

kind-up:
	kind create cluster --name $(KIND_CLUSTER) --config scripts/kind-config.yaml || true

kind-down:
	kind delete cluster --name $(KIND_CLUSTER) || true

# Apply platform base (namespaces + PSA labels)
base-apply:
	kubectl apply -k gitops/base

# Bootstrap ArgoCD (App of Apps)
# NOTE: ArgoCD itself must already be installed in the argocd namespace.
argocd-bootstrap:
	kubectl apply -f gitops/argocd/bootstrap/app-of-apps.yaml

# Optional: install the app via Helm directly (without Argo)
helm-app-install:
	helm dependency update apps/helm/voting-app
	helm upgrade --install voting-app apps/helm/voting-app -n voting -f apps/helm/voting-app/values.yaml -f apps/helm/voting-app/values-dev.yaml

helm-app-uninstall:
	helm uninstall voting-app -n voting || true

# Deterministic local deploy for Minikube using the running node runtime.
minikube-local-deploy:
	MINIKUBE_PROFILE=$(MINIKUBE_PROFILE) KUBE_NAMESPACE=$(KUBE_NAMESPACE) HELM_RELEASE=$(HELM_RELEASE) ./scripts/minikube-local-deploy.sh
