#!/usr/bin/env bash
# Vérifie que chaque manifeste malveillant de attacks/ est REFUSÉ par le cluster,
# et que l'application légitime tourne bien. Code retour != 0 si une défense est contournée.
set -uo pipefail
cd "$(dirname "$0")/.."

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
failures=0

for f in attacks/*.yaml; do
  if out=$(kubectl apply -f "$f" 2>&1); then
    echo -e "${RED}[FAIL]${NC} $f a été ACCEPTÉ : la défense est contournée !"
    kubectl delete -f "$f" --ignore-not-found >/dev/null 2>&1
    failures=$((failures + 1))
  else
    reason=$(echo "$out" | grep -oE "(violates PodSecurity[^:]*|policy [a-z-]+|exceeded quota|must specify [a-z.,]+)" | head -1)
    echo -e "${GREEN}[ OK ]${NC} $f refusé  ->  ${reason:-$out}"
  fi
done

echo
ready=$(kubectl -n secure-app get deploy web -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
if [[ "${ready:-0}" -ge 1 ]]; then
  echo -e "${GREEN}[ OK ]${NC} L'application légitime tourne ($ready réplicas prêts)"
else
  echo -e "${RED}[FAIL]${NC} L'application légitime n'est pas prête"
  failures=$((failures + 1))
fi

echo
if [[ $failures -eq 0 ]]; then
  echo -e "${GREEN}Toutes les attaques ont été bloquées.${NC}"
else
  echo -e "${RED}$failures test(s) en échec.${NC}"
fi
exit "$failures"
