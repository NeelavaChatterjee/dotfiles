# Cache slow completions; load fast ones directly.
mkdir -p "$ZDOTDIR/cache"
for tool in kubectl helm k9s; do
  cache="$ZDOTDIR/cache/$tool"
  if [[ ! -f $cache ]] && command -v $tool >/dev/null; then
    $tool completion zsh > $cache 2>/dev/null
  fi
  [[ -f $cache ]] && source $cache
done
command -v gh >/dev/null && eval "$(gh completion -s zsh)"
