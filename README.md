# ☸️ Kubernetes Security Lab

![K8s](https://github.com/Aj3036max/k8s-security-lab/actions/workflows/k8s.yml/badge.svg)
![Kubernetes](https://img.shields.io/badge/kubernetes-hardened-326CE5?logo=kubernetes&logoColor=white)
![Kyverno](https://img.shields.io/badge/policy-kyverno-orange)

Lab de **durcissement Kubernetes** avec une approche **attaque / défense** :
un cluster local (kind) sécurisé en profondeur, et 6 manifestes malveillants qui **doivent tous être refusés**.
La CI crée un vrai cluster à chaque push et rejoue les attaques automatiquement.

## 🛡️ Défense en profondeur

| Couche | Mesure | Fichier |
|---|---|---|
| Admission | **Pod Security Admission** `restricted` sur le namespace | `manifests/00-namespace.yaml` |
| Admission | **Kyverno** : pas de `:latest`, registres autorisés, limites obligatoires, rootfs read-only | `policies/kyverno-policies.yaml` |
| Identité | ServiceAccount dédié sans droits, token non monté, Role lecture seule (sans secrets) | `manifests/10-rbac.yaml` |
| Workload | non-root, `readOnlyRootFilesystem`, `drop: ALL`, seccomp `RuntimeDefault`, pas d'escalade | `manifests/20-deployment.yaml` |
| Réseau | **NetworkPolicies** zero-trust : default deny ingress + egress, DNS et HTTP seulement | `manifests/30-networkpolicies.yaml` |
| Ressources | ResourceQuota (anti-DoS), PodDisruptionBudget | `manifests/40-resource-quota.yaml` |
| Audit | Journal d'audit de l'API server (exec, RBAC, accès aux secrets) | `cluster/audit-policy.yaml` |

## 🔴 Attaques testées

| Attaque | Résultat attendu |
|---|---|
| Pod privilégié (évasion vers le nœud) | ❌ refusé par PSA |
| Montage `hostPath: /` | ❌ refusé par PSA |
| Conteneur root | ❌ refusé par PSA |
| Image `:latest` | ❌ refusé par Kyverno |
| Image d'un registre inconnu (cryptominer) | ❌ refusé par Kyverno |
| Pas de limites CPU/RAM | ❌ refusé par Kyverno / ResourceQuota |

Détails et explications : [`attacks/README.md`](attacks/README.md)

## 🚀 Lancer le lab

Prérequis : Docker, [kind](https://kind.sigs.k8s.io/), kubectl (sous Windows : utiliser WSL2 ou Git Bash).

```bash
./scripts/setup.sh          # cluster 3 nœuds + Calico + Kyverno + application (~5 min)
./scripts/test-attacks.sh   # rejoue les 6 attaques
curl http://127.0.0.1:8080  # l'application légitime fonctionne
./scripts/teardown.sh       # supprime le cluster
```

Exemple de sortie :

```
[ OK ] attacks/01-privileged-pod.yaml refusé  ->  violates PodSecurity "restricted:latest"
[ OK ] attacks/04-latest-tag.yaml refusé  ->  policy disallow-latest-tag
[ OK ] attacks/05-untrusted-registry.yaml refusé  ->  policy restrict-image-registries
...
[ OK ] L'application légitime tourne (2 réplicas prêts)
Toutes les attaques ont été bloquées.
```

## ✅ CI

1. **kubeconform** : validation des manifestes contre les schémas Kubernetes
2. **Checkov** : 100 contrôles de bonnes pratiques passés (exceptions justifiées dans `.checkov.yml`)
3. **e2e** : création d'un cluster kind dans GitHub Actions, installation de Kyverno, exécution des attaques

## 📚 Ce que j'ai appris

- Pod Security Standards (privileged / baseline / restricted) et Pod Security Admission
- Policy as Code avec Kyverno
- RBAC en moindre privilège, NetworkPolicies et nécessité d'un CNI compatible (Calico)
- Les vecteurs d'évasion de conteneur et comment les bloquer
- Référentiels : CIS Kubernetes Benchmark, NSA/CISA Kubernetes Hardening Guide
