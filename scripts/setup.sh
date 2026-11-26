#!/usr/bin/env bash
# Crée le cluster kind durci, installe Calico (NetworkPolicies) + Kyverno, puis déploie l'application.
# Prérequis : docker, kind, kubectl.
set -euo pipefail
cd "$(dirname "$0")/.."

CALICO_VERSION="${CALICO_VERSION:-v3.33.1}"
KYVERNO_VERSION="${KYVERNO_VERSION:-v1.20.0}"
KIND_CONFIG="${KIND_CONFIG:-cluster/kind-config.yaml}"

echo "==> Création du cluster kind ($KIND_CONFIG)"
kind create cluster --config "$KIND_CONFIG" --wait 0s

if grep -q "disableDefaultCNI: true" "$KIND_CONFIG"; then
  echo "==> Installation de Calico $CALICO_VERSION (support des NetworkPolicies)"
  kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"
  kubectl -n kube-system rollout status ds/calico-node --timeout=300s
fi
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "==> Installation de Kyverno $KYVERNO_VERSION"
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
kubectl -n kyverno rollout status deploy/kyverno-admission-controller --timeout=300s

echo "==> Application des politiques et des manifestes"
kubectl apply -f policies/
kubectl apply -f manifests/
kubectl -n secure-app rollout status deploy/web --timeout=180s

echo
echo "✅ Cluster prêt. Application : http://127.0.0.1:8080 (si cluster/kind-config.yaml)"
echo "   Lancer les tests d'attaque : ./scripts/test-attacks.sh"
