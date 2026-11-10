#!/usr/bin/env bash
# Check that the workstation is ready for the course.
set -u
ok=0
check() { # check <name> <command...>
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then echo "✅ $name"; else echo "❌ $name"; ok=1; fi
}
check "git installed"             git --version
check "git user.name configured"  git config user.name
check "docker installed"          docker --version
check "docker daemon accessible"  docker info
# Internet access is needed to download the hello-world image.
check "docker run hello-world"    docker run --rm hello-world
check "python3 >= 3.11"           python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))'
check "just installed"            just --version
check "gh installed"              gh --version
check "gh authenticated"          gh auth status
[ $ok -eq 0 ] && echo "🎉 Everything is ready." || echo "⚠️ Fix the ❌ checks before continuing (see README)."
exit $ok
