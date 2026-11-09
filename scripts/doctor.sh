#!/usr/bin/env bash
# Vérifie que le poste est prêt pour le cours.
set -u
ok=0
check() { # check <nom> <commande...>
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then echo "✅ $name"; else echo "❌ $name"; ok=1; fi
}
check "git installé"              git --version
check "git user.name configuré"   git config user.name
check "docker installé"           docker --version
check "docker daemon accessible"  docker info
# nécessite Internet pour télécharger l'image hello-world
check "docker run hello-world"    docker run --rm hello-world
check "python3 >= 3.11"           python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))'
check "gh installé"               gh --version
check "gh authentifié"            gh auth status
[ $ok -eq 0 ] && echo "🎉 Tout est prêt." || echo "⚠️ Corrige les ❌ avant de continuer (voir README)."
exit $ok
