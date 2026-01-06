SHELL := /bin/bash

KIND_CLUSTER ?= tqp

.PHONY: kind-up kind-down platform-install app-install app-uninstall

kind-up:
	kind create cluster --name $(KIND_CLUSTER) --config scripts/kind-config.yaml || true

kind-down:
	kind delete cluster --name $(KIND_CLUSTER) || true

platform-install:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	kubectl apply -f platform/namespaces.yaml
	kubectl apply -f platform/psa-labels.yaml
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx -f platform/helm/ingress-nginx-values.yaml
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f platform/helm/monitoring-values.yaml

app-install:
	helm dependency update apps/helm/voting-app
	helm upgrade --install voting-app apps/helm/voting-app -n voting --create-namespace -f apps/helm/voting-app/values.yaml -f apps/helm/voting-app/values-dev.yaml

app-uninstall:
	helm uninstall voting-app -n voting || true
