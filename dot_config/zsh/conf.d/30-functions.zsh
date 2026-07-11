# From dev-setup-notes.md starter set
kshell() { kubectl exec -it "$1" -- "${2:-bash}"; }
klogs() { stern --tail=100 "$@"; }
jq-clip() { pbpaste | jq "${1:-.}"; }
listening() { lsof -iTCP -sTCP:LISTEN -n -P | grep LISTEN; }
venv() { source .venv/bin/activate; }

# Natural extensions
mkcd() { mkdir -p "$1" && cd "$1"; }
kpods() {
  kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase, restarts: ([.status.containerStatuses[].restartCount] | add)}'
}

# Dotfiles introspection: what this machine IS, what's drifted, what brew is missing.
dotstatus() {
  echo "== machine =="
  chezmoi data | jq '{role, os: .chezmoi.os, headless, packagesSkip, source: .chezmoi.sourceDir}'
  echo "== dotfile drift (chezmoi) =="
  chezmoi status || true
  echo "== packages vs manifest =="
  local role src
  role="$(chezmoi data | jq -r '.role')"
  src="$(chezmoi data | jq -r '.chezmoi.sourceDir')"
  cat "$src/packages/Brewfile.common" "$src/packages/Brewfile.$role" 2>/dev/null \
    | grep -E '^(brew|cask)' | brew bundle check --file=/dev/stdin || true
}
