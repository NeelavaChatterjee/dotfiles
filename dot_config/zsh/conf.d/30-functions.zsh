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
