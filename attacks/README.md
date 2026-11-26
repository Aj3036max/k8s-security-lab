# 🔴 Scénarios d'attaque (Red Team) et défenses (Blue Team)

Chaque manifeste de ce dossier représente une **mauvaise pratique exploitable**.
Le cluster durci doit **tous les refuser**. Le script `scripts/test-attacks.sh` le vérifie automatiquement.

| Fichier | Attaque | Pourquoi c'est dangereux | Bloqué par |
|---|---|---|---|
| `01-privileged-pod.yaml` | Pod `privileged: true` | Accès à tous les devices de l'hôte → évasion du conteneur, prise de contrôle du nœud | Pod Security Admission (restricted) |
| `02-hostpath-escape.yaml` | Monte `/` de l'hôte | Lecture de `/etc/shadow`, des clés kubelet, écriture d'une crontab sur le nœud | Pod Security Admission |
| `03-root-user.yaml` | Conteneur en root (UID 0) | Une faille applicative donne root dans le conteneur, facilite l'évasion | Pod Security Admission |
| `04-latest-tag.yaml` | Image `:latest` | Version non maîtrisée, empoisonnement de tag | Kyverno `disallow-latest-tag` |
| `05-untrusted-registry.yaml` | Image d'un registre inconnu | Supply chain : image piégée (cryptominer, backdoor) | Kyverno `restrict-image-registries` |
| `06-no-limits.yaml` | Pas de limites CPU/RAM | Un pod peut épuiser le nœud (DoS) | Kyverno `require-resource-limits` |

Test de mouvement latéral (NetworkPolicy) :

```bash
# Un pod "attaquant" dans un autre namespace tente de joindre l'app : autorisé sur 8080 uniquement
kubectl run attacker -n default --rm -it --image=busybox:1.36 -- wget -qO- -T 3 http://web.secure-app.svc/
# Depuis l'app, tentative d'exfiltration vers Internet : bloquée par default-deny-all (egress)
kubectl exec -n secure-app deploy/web -- wget -qO- -T 3 http://example.com   # => timeout
```
