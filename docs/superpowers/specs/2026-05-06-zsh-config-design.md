# Zsh Config — Design

**Date:** 2026-05-06
**Repo:** `~/platform9/dotfiles` (target visibility: public on GitHub)
**Spec for:** the zsh configuration layer of the dotfiles repo. The Brewfile (tooling install manifest) is already complete; this design covers what gets shipped on top of it.
**Source of truth for tooling philosophy:** `dev-setup-notes.md` at the repo root. Read first.

---

## 1. Context & Goals

A from-scratch rewrite of `~/.zshrc`, replacing the current oh-my-zsh-based setup. The rewrite is being done deliberately because the existing config has accumulated cruft (manual brew-path plugin sourcing duplicates OMZ's loader, `compinit` runs twice, OMZ's load overhead conflicts with the sub-100ms startup goal).

### Goals

- **Sub-100ms steady-state startup**, achievable <50ms per the notes (static-load antidote + p10k instant prompt).
- **Lean and explicit** — every plugin and feature pulls its weight; no OMZ.
- **Portable across multiple MacBooks** via chezmoi-managed deployment.
- **Public-shareable** — Rackspace-internal context isolated to a gitignored work file.
- **Future-proof for ZDOTDIR** — the layout already lives under `$HOME/.config/zsh` so the eventual switch to a system-wide `/etc/zshenv` ZDOTDIR setter is a one-line change with zero rewrites.

### Non-goals (deferred)

- Linux variant of the config — handled separately when needed.
- Atuin sync server (multi-machine history sync) — flip on later when worth the privacy tradeoff.
- Bootstrap automation beyond what chezmoi gives natively (e.g. a one-command shell-script bootstrap is out of scope for v1).
- The rest of the dev-setup-notes.md backlog (tmux config, neovim/LazyVim, ssh config, chezmoi adoption beyond zsh) — each is its own design.

---

## 2. Locked Decisions

The brainstorm produced these as the foundation:

| # | Decision | Rationale |
|---|---|---|
| 1 | **Layout: modular** — `.zshenv`, `.zshrc`, `conf.d/` (numbered fragments) | Clean separation of env vs interactive setup; per-concern files <100 lines; supports growth without monolithic-file pain |
| 2 | **Plugin manager: antidote** (static-load pattern) | Notes' decision; recommended for new setups; static-load is the path to <100ms |
| 3 | **Plugin set: lean — only the four essentials** | sub-100ms goal; OMZ-derived aliases are fragile across OMZ releases; hand-rolled aliases are durable |
| 4 | **ZDOTDIR target: `$HOME/.config/zsh`** (XDG) | Standard; composes with rest of XDG ecosystem (`~/.config/nvim`, etc.) |
| 5 | **Bootstrap: `~/.zshenv` (user-level)** | Portable via chezmoi; no sudo; survives macOS updates; only file in `$HOME` |
| 6 | **Deploy: chezmoi** | Notes' choice; multi-mac templating; encrypted secrets pathway via age/sops |
| 7 | **History: pure atuin** — owns both `Ctrl-R` and `↑` | Uniform UX; zsh history file kept as passive backup for atuin DB recovery |
| 8 | **p10k config: carry over verbatim** from existing `~/.p10k.zsh` | Same prompt on every mac is muscle memory |
| 9 | **Repo visibility: public** — corp-specific in gitignored `99-work.zsh` | Preserves option to publish; forces clean separation |
| 10 | **Completion cache: `kubectl`, `helm`, `k9s`** (not `gh`) | The slow ones get cached; gh is fast enough to load directly |

---

## 3. Architecture & File Layout

```
~/platform9/dotfiles/                       (the dotfiles repo)
├── Brewfile                                (already complete — install manifest)
├── README.md
├── dev-setup-notes.md                      (philosophy / source of truth)
├── docs/superpowers/specs/                 (this doc lives here)
├── .gitignore                              (excludes 99-work.zsh, cache/, atuin DB, etc.)
├── dot_zshenv                              → ~/.zshenv          (3-line bootstrap)
└── dot_config/
    ├── atuin/
    │   └── config.toml                     → ~/.config/atuin/config.toml
    └── zsh/
        ├── dot_zshenv                      → ~/.config/zsh/.zshenv
        ├── dot_zshrc                       → ~/.config/zsh/.zshrc
        ├── dot_zsh_plugins.txt             → ~/.config/zsh/.zsh_plugins.txt
        ├── dot_p10k.zsh                    → ~/.config/zsh/.p10k.zsh   (carried over)
        ├── cache/                          (gitignored — completion cache)
        └── conf.d/
            ├── 00-options.zsh              → ~/.config/zsh/conf.d/00-options.zsh
            ├── 10-completions.zsh
            ├── 20-aliases.zsh
            ├── 30-functions.zsh
            ├── 40-kube.zsh
            ├── 99-work.zsh.example         (committed template)
            └── 99-work.zsh                 (gitignored — corp-specific)
```

### Layout rationale

- `~/.zshenv` is the only file that lives in `$HOME` — sets `ZDOTDIR` and forwards. Future `/etc/zshenv` migration only adds the same export there.
- `conf.d/` files are **numerically prefixed for explicit load order**. Lower numbers run first. Choices follow: options before completions; completions before aliases/functions that reference completed commands; work file last (`99-`) so it can override anything else.
- `cache/` is gitignored because completion files are regenerated per machine.
- `99-work.zsh.example` is committed as a template; the real `99-work.zsh` is gitignored. A fresh `chezmoi apply` produces a known-good shell even with no work file present.

### `.gitignore` (chezmoi-source naming)

```
# zsh — runtime/derived files we don't want in the repo
dot_config/zsh/cache/
dot_config/zsh/conf.d/99-work.zsh
dot_config/zsh/dot_zsh_history
dot_config/zsh/dot_zcompdump*
dot_config/zsh/dot_zsh_plugins.zsh

# atuin local DB (not the config; only the DB)
dot_local/share/atuin/

# OS noise
.DS_Store
```

`dot_zsh_plugins.zsh` (antidote-compiled output) is gitignored because it's machine-derived from `.zsh_plugins.txt`. Note: chezmoi has its own `.chezmoiignore` mechanism for files-in-source-but-not-deployed, distinct from `.gitignore`. For this design we use `.gitignore` only — none of the gitignored items belong in the chezmoi source either.

---

## 4. Boot Flow / Load Order

What happens when zsh starts. This dictates everything else's correctness.

```
zsh launches
    ↓
1. ~/.zshenv  (always runs, including non-interactive shells like cron/scripts)
       • exports ZDOTDIR="$HOME/.config/zsh"
       • sources $ZDOTDIR/.zshenv if present
    ↓
2. $ZDOTDIR/.zshenv
       • XDG_* exports
       • Homebrew shellenv (Apple Silicon primary, Intel fallback)
       • PATH construction with auto-dedup (typeset -U)
       • LANG, LC_ALL, EDITOR, VISUAL, PAGER, MANPAGER
       • Less defaults
       • Homebrew preferences
       (No prompts, no plugin loading — must stay fast and side-effect free)
    ↓ (interactive shells only beyond this point)
3. $ZDOTDIR/.zshrc
   3a. p10k instant prompt block             (FIRST — before anything that prints)
   3b. setopt block + bindkey                (history, navigation, misc)
   3c. antidote bootstrap → load .zsh_plugins.txt (static-load pattern)
   3d. compinit -C                           (skip security check; cache trust assumed)
   3e. Source conf.d/*.zsh in numeric order:
         00-options.zsh
         10-completions.zsh
         20-aliases.zsh
         30-functions.zsh
         40-kube.zsh
         99-work.zsh                         (loaded only if file present)
   3f. Tool hooks (eager — all instant):
         zoxide, direnv, fnm, fzf, atuin     (atuin LAST so it claims Ctrl-R)
   3g. p10k.zsh source                       (LAST — finalizes prompt)
```

### Key rules

- **Instant prompt is first** so the user sees a prompt within ~10ms even on a cold start.
- **Plugins load before `compinit`** so plugin-provided completion functions populate `fpath` before init.
- **`fast-syntax-highlighting` loads last** among plugins so it observes other plugins' redrawing.
- **`conf.d/` runs after `compinit`** so functions/aliases that reference completion-defined helpers don't error.
- **Tool hooks run after `conf.d/`** so anything corp-specific in `99-work.zsh` (e.g. atuin server URL override) is set before the relevant init.
- **atuin is the last hook** because both atuin and fzf rebind `Ctrl-R`; whichever runs last wins, and we want atuin to win.

### Profiling toggle

`zmodload zsh/zprof` at the very top of `.zshrc` and `zprof` at the very bottom — both commented. Uncomment when investigating slow startup; restart the shell to see the time-attributed call tree.

---

## 5. Plugin & Prompt Setup

### `$ZDOTDIR/.zsh_plugins.txt`

```
zsh-users/zsh-completions       kind:fpath path:src
Aloxaf/fzf-tab
zsh-users/zsh-autosuggestions
zdharma-continuum/fast-syntax-highlighting
```

Order matters. `kind:fpath` on `zsh-completions` tells antidote not to source it — just put `src/` on `fpath` for `compinit` to pick up.

### Antidote loader (in `.zshrc` between `setopt` and `compinit`)

```zsh
# Static-load: compile .zsh_plugins.txt → .zsh_plugins.zsh only when txt is newer.
# Steady-state startup just sources the precompiled file.
ANTIDOTE_HOME="${HOMEBREW_PREFIX:-/opt/homebrew}/share/antidote"
zsh_plugins="$ZDOTDIR/.zsh_plugins.zsh"

if [[ ! $zsh_plugins -nt $ZDOTDIR/.zsh_plugins.txt ]]; then
  source "$ANTIDOTE_HOME/antidote.zsh"
  antidote bundle <"$ZDOTDIR/.zsh_plugins.txt" >|"$zsh_plugins"
fi

source "$zsh_plugins"
```

### p10k

- Instant prompt block (carried verbatim from existing `~/.zshrc` lines 4–6) at the very top of `.zshrc`.
- Theme sourced directly from the brew-installed formula, NOT via antidote (faster, p10k has its own optimized init):
  ```zsh
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/powerlevel10k/powerlevel10k.zsh-theme"
  ```
- Carried-over `~/.config/zsh/.p10k.zsh` sourced last in `.zshrc`:
  ```zsh
  [[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh
  ```

---

## 6. `conf.d/` Contents

### `00-options.zsh`

```zsh
# History (atuin handles search; this is on-disk backup)
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY

# Navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Misc
setopt INTERACTIVE_COMMENTS EXTENDED_GLOB NO_BEEP

bindkey -e  # emacs-style line editing (universal across remote shells)

# fzf-tab styling
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:kubectl_*:*' fzf-preview 'kubectl explain $word 2>/dev/null || echo no preview'
zstyle ':fzf-tab:*' fzf-flags --height=40% --reverse
```

### `10-completions.zsh`

```zsh
mkdir -p "$ZDOTDIR/cache"
for tool in kubectl helm k9s; do
  cache="$ZDOTDIR/cache/$tool"
  if [[ ! -f $cache ]] && command -v $tool >/dev/null; then
    $tool completion zsh > $cache 2>/dev/null
  fi
  [[ -f $cache ]] && source $cache
done
command -v gh >/dev/null && eval "$(gh completion -s zsh)"
```

### `20-aliases.zsh`

Hand-rolled. Notes' "don't alias over originals" rule is respected — wrappers use new names — except for `kubectl→kubecolor` which the notes explicitly endorse.

```zsh
# Editor
alias v=nvim vi=nvim vim=nvim

# Eza wrappers (own names)
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2'

# Bat with own name
alias bcat='bat --paging=never --style=plain'

# Git
alias g=git
alias gst='git status -sb'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gp='git pull --rebase'
alias gP='git push'

# Kubernetes
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias klog='kubectl logs -f'
alias kx=kubectx
alias kn=kubens

# Misc
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n"'
```

### `30-functions.zsh`

Notes' starter set + two natural extensions.

```zsh
# From dev-setup-notes.md
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
```

### `40-kube.zsh`

```zsh
# kubecolor as kubectl — notes' explicit exception to "don't alias over originals"
command -v kubecolor >/dev/null && alias kubectl=kubecolor
compdef kubecolor=kubectl
```

### `99-work.zsh.example` (committed; `99-work.zsh` is gitignored)

```zsh
# Copy to 99-work.zsh and fill in.
# Gitignored — Rackspace-internal stuff lives here.
# Examples:
# export AWS_PROFILE=...
# alias ksaml='saml2aws login -a ...'
# alias kdev='kubectl --context=...'
```

---

## 7. Tool Hooks

In `.zshrc`, after the `conf.d/` sourcing block. Each guarded so missing tools don't break startup.

```zsh
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd z)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v fnm    >/dev/null && eval "$(fnm env --use-on-cd)"
command -v fzf    >/dev/null && source <(fzf --zsh)
command -v atuin  >/dev/null && eval "$(atuin init zsh)"   # last so it owns Ctrl-R + ↑
```

### Per-hook notes

- **zoxide `--cmd z`** — registers as `z`, leaving `cd` untouched. `z dotfiles` jumps via frecency.
- **direnv** — auto-loads `.envrc` on `cd`. Replaces ad-hoc `source .env` patterns.
- **fnm `--use-on-cd`** — auto-switches Node versions on `.nvmrc`/`.node-version`.
- **fzf `--zsh`** — modern brew fzf provides shell integration via this single line. Gives `Ctrl-T` (file picker), `Alt-C` (cd picker). Any `Ctrl-R` binding it sets is overridden by the next line.
- **atuin** — default init binds both `Ctrl-R` and `↑` (pure-atuin decision). Tuned via the config file below.

### Key ownership

| Key | Owner | What |
|---|---|---|
| `Ctrl-R` | atuin | Fuzzy search across all history (SQLite, exit-code-aware, time-aware) |
| `↑` | atuin | Fuzzy recall scoped to current session (per `session` filter) |
| `Ctrl-T` | fzf | File picker in cwd |
| `Alt-C` | fzf | cd-into-dir picker |

### `~/.config/atuin/config.toml`

```toml
filter_mode_shell_up_key_binding = "session"   # ↑ recalls within current session only
filter_mode = "global"                         # Ctrl-R searches everything
search_mode = "fuzzy"                          # fzf-style scoring; Ctrl-S in TUI to switch
# Sync (deferred):
# sync_address = "https://api.atuin.sh"
# auto_sync = true
```

---

## 8. `.zshenv` Contents

### `~/.zshenv` — bootstrap (3 lines)

```zsh
export ZDOTDIR="$HOME/.config/zsh"
[[ -f $ZDOTDIR/.zshenv ]] && source $ZDOTDIR/.zshenv
```

### `$ZDOTDIR/.zshenv` — the real env

```zsh
# XDG dirs (set early — many tools key off these)
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Homebrew (Apple Silicon primary, Intel fallback)
if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew    ]]; then eval "$(/usr/local/bin/brew shellenv)"
fi

# PATH: user-local first (uv tools override brew on shadow), then brew (above), then system
typeset -U path PATH
path=(
  $HOME/.local/bin
  $HOME/.krew/bin
  $HOME/go/bin
  $path
)
export PATH

# Locale (containers / SSH'd shells often miss this)
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Editor / pager
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export MANPAGER='nvim +Man!'

# Less defaults: smart-case, raw color, quit-on-one-screen, preserve output, mouse
export LESS='-iR -F -X --mouse'

# Homebrew preferences
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_BUNDLE_FILE="$HOME/platform9/dotfiles/Brewfile"
```

### Why `.zshenv` and not `.zshrc`

Scripts run by cron, `git commit`-launched editors, or `zsh -c '...'` invocations are non-interactive — they don't run `.zshrc`. Anything that needs to be visible in those contexts (PATH, EDITOR, locale) goes here.

---

## 9. Verification & Bootstrap

### Startup target

Per dev-setup-notes.md: <100ms steady-state, achievable <50ms.

```bash
hyperfine --warmup 3 'zsh -i -c exit'
```

If steady-state is over 150ms, profile by uncommenting the `zprof` block in `.zshrc`.

### Fresh-mac bootstrap (from zero to working shell)

```bash
# 1. Xcode CLI tools
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. chezmoi + apply
brew install chezmoi
chezmoi init https://github.com/<you>/dotfiles
chezmoi apply

# 4. brew bundle (uses HOMEBREW_BUNDLE_FILE from .zshenv once shell is live; can also pass --file)
brew bundle install --file=~/platform9/dotfiles/Brewfile

# 5. fnm node + corepack
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default $(fnm current)
corepack enable

# 6. Krew plugins
kubectl krew install neat oidc-login virt

# 7. New shell — config is live
exec zsh
```

### Verification checklist

```bash
echo $ZDOTDIR                                   # /Users/<you>/.config/zsh
[[ -f ~/.zshenv ]] && [[ -f $ZDOTDIR/.zshrc ]]
[[ -d $ZDOTDIR/conf.d ]]
ls $ZDOTDIR/cache/                              # kubectl, helm, k9s after first use
command -v atuin && command -v zoxide && command -v direnv && command -v fnm
echo "${path[@]}"                               # confirm PATH order
type k                                          # alias for kubectl
type kubectl                                    # alias for kubecolor
fc -l 1 | head                                  # zsh history file recording
atuin search --limit 5 "git"                    # atuin DB populated
```

Manual checks (can't be scripted):

- Press `Ctrl-R` — atuin TUI opens.
- Press `↑` in a fresh terminal — atuin's session-filtered recall.
- `cd` into a project with a `.envrc` — direnv prompts to allow.

### Recovery from a broken zshrc

```bash
ZDOTDIR=/tmp zsh    # bypasses your config
zsh --no-rcs        # zsh with NO config files at all
```

---

## 10. Open Threads / Future Iterations

Not blocking v1; revisit as needed:

- **Atuin sync server** — flip on once cross-mac history starts mattering. Privacy decision.
- **Migration from `/etc/zshenv` ZDOTDIR** — switch is one line + filesystem move; deferred until the user wants to remove the `~/.zshenv` from `$HOME` entirely.
- **Per-machine chezmoi templates** — `99-work.zsh.example` could become `99-work.zsh.tmpl` if work content needs hostname-conditional logic.
- **Bootstrap automation** — a single shell script wrapping the bootstrap flow above, separate design.
- **mockgen → mockery migration** — separate decision when convenient.
- **Adding zsh-history-substring-search or other plugins** — only if a concrete use case arises.

---

## 11. Acceptance Criteria

This design is complete when, after a fresh `chezmoi apply` on a new mac followed by the bootstrap steps in §9:

1. `zsh -i -c exit` benchmarks under 100ms steady-state.
2. All verification-checklist commands in §9 succeed.
3. Both manual checks (`Ctrl-R` opens atuin, `↑` shows session-filtered recall, direnv prompts on `.envrc`) work as expected.
4. The shell launches without errors even if `99-work.zsh` is missing.
5. The repo contains no Rackspace-internal hostnames, context names, account IDs, or aliases.
