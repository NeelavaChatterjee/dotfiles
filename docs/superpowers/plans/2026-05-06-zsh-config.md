# Zsh Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the chezmoi-managed zsh config artifacts in this repo, end-to-end smoke-tested in a sandbox, ready for a future `chezmoi apply` to deploy. No live `$HOME` deploy in this scope.

**Architecture:** Modular zsh layout — `~/.zshenv` bootstrap that hands off to `$ZDOTDIR=$HOME/.config/zsh`, with numbered `conf.d/*.zsh` fragments sourced by `.zshrc`. Antidote with the static-load pattern provides plugins. Atuin owns Ctrl-R + ↑. p10k provides the prompt. All target sub-100ms steady-state startup.

**Tech Stack:** zsh, antidote, powerlevel10k, atuin, zoxide, direnv, fnm, fzf, chezmoi, hyperfine.

**Spec:** `docs/superpowers/specs/2026-05-06-zsh-config-design.md` — read first.

**Working directory:** `/Users/neelava/platform9/dotfiles` (branch `dev-initial`).

**Commit rule:** No `Co-Authored-By: Claude` trailer on any commit. Plain commit messages only.

---

## File map

Files to create (chezmoi-source naming on left → deployed path on right):

| Source path (in repo) | Deployed path (after `chezmoi apply`) | Responsibility |
|---|---|---|
| `dot_zshenv` | `~/.zshenv` | 3-line bootstrap: set ZDOTDIR, source `$ZDOTDIR/.zshenv` |
| `dot_config/zsh/dot_zshenv` | `~/.config/zsh/.zshenv` | XDG dirs, brew shellenv, PATH, locale, EDITOR/PAGER, less defaults |
| `dot_config/zsh/dot_zshrc` | `~/.config/zsh/.zshrc` | Interactive setup: instant prompt, setopt, antidote, compinit, conf.d sourcing, tool hooks, p10k source |
| `dot_config/zsh/dot_zsh_plugins.txt` | `~/.config/zsh/.zsh_plugins.txt` | Antidote plugin manifest (4 entries) |
| `dot_config/zsh/dot_p10k.zsh` | `~/.config/zsh/.p10k.zsh` | p10k prompt config — copied verbatim from current `~/.p10k.zsh` |
| `dot_config/zsh/conf.d/00-options.zsh` | `~/.config/zsh/conf.d/00-options.zsh` | Shell options, history config, fzf-tab styling, bindkey |
| `dot_config/zsh/conf.d/10-completions.zsh` | `~/.config/zsh/conf.d/10-completions.zsh` | Cached completions for kubectl/helm/k9s + direct gh |
| `dot_config/zsh/conf.d/20-aliases.zsh` | `~/.config/zsh/conf.d/20-aliases.zsh` | Hand-rolled aliases (editor, eza, git, k8s) |
| `dot_config/zsh/conf.d/30-functions.zsh` | `~/.config/zsh/conf.d/30-functions.zsh` | Notes' starter functions + extensions |
| `dot_config/zsh/conf.d/40-kube.zsh` | `~/.config/zsh/conf.d/40-kube.zsh` | kubecolor alias + compdef |
| `dot_config/zsh/conf.d/99-work.zsh.example` | `~/.config/zsh/conf.d/99-work.zsh.example` | Template for gitignored corp-specific file |
| `dot_config/atuin/config.toml` | `~/.config/atuin/config.toml` | Atuin filter modes + search mode |
| `.gitignore` | (not deployed) | Repo-level git ignores |
| `.chezmoiignore` | (not deployed) | Tells chezmoi which source files to skip when applying |

13 files total. Each file has one responsibility. No file exceeds ~80 lines. Numeric prefixes in `conf.d/` lock load order.

---

## Task 1: `.gitignore` and `.chezmoiignore`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/.gitignore`
- Create: `/Users/neelava/platform9/dotfiles/.chezmoiignore`

- [ ] **Step 1: Write `.gitignore`**

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

- [ ] **Step 2: Write `.chezmoiignore`**

```
# Repo metadata and docs — not part of the deployed dotfiles
README.md
LICENSE
Brewfile
dev-setup-notes.md
docs
docs/**
```

- [ ] **Step 3: Verify both files exist and are non-empty**

Run: `ls -la .gitignore .chezmoiignore && wc -l .gitignore .chezmoiignore`
Expected: both files present, each with several lines.

- [ ] **Step 4: Commit**

```bash
git add .gitignore .chezmoiignore
git commit -m "add gitignore and chezmoiignore"
```

Verify: `git log -1 --format=fuller` — confirm no Co-Authored-By line.

---

## Task 2: `~/.zshenv` bootstrap (`dot_zshenv` at repo root)

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_zshenv`

- [ ] **Step 1: Write the file**

```zsh
# Bootstrap: zsh reads this from $HOME first, then defers everything to $ZDOTDIR.
export ZDOTDIR="$HOME/.config/zsh"
[[ -f $ZDOTDIR/.zshenv ]] && source $ZDOTDIR/.zshenv
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_zshenv`
Expected: no output, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add dot_zshenv
git commit -m "add zshenv bootstrap (sets ZDOTDIR, forwards to xdg)"
```

---

## Task 3: `$ZDOTDIR/.zshenv` (`dot_config/zsh/dot_zshenv`)

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/dot_zshenv`

- [ ] **Step 1: Create the parent directory**

Run: `mkdir -p dot_config/zsh/conf.d`

- [ ] **Step 2: Write the file**

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

- [ ] **Step 3: Syntax-check**

Run: `zsh -n dot_config/zsh/dot_zshenv`
Expected: no output, exit 0.

- [ ] **Step 4: Smoke-test in isolation**

Run: `zsh -c 'source dot_config/zsh/dot_zshenv && echo "PATH=$PATH" && echo "EDITOR=$EDITOR"'`
Expected: PATH includes `~/.local/bin`, `~/.krew/bin`, `~/go/bin`, plus the brew-set ones; `EDITOR=nvim`.

- [ ] **Step 5: Commit**

```bash
git add dot_config/zsh/dot_zshenv
git commit -m "add zsh env file (xdg, brew shellenv, path, locale, editor)"
```

---

## Task 4: Antidote plugin manifest

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/dot_zsh_plugins.txt`

- [ ] **Step 1: Write the file**

```
zsh-users/zsh-completions       kind:fpath path:src
Aloxaf/fzf-tab
zsh-users/zsh-autosuggestions
zdharma-continuum/fast-syntax-highlighting
```

- [ ] **Step 2: Verify line count and no shell parsing required**

Run: `wc -l dot_config/zsh/dot_zsh_plugins.txt`
Expected: 4 lines.

- [ ] **Step 3: Commit**

```bash
git add dot_config/zsh/dot_zsh_plugins.txt
git commit -m "add antidote plugin manifest (4 essentials, lean philosophy)"
```

---

## Task 5: `conf.d/00-options.zsh`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/conf.d/00-options.zsh`

- [ ] **Step 1: Write the file**

```zsh
# History — atuin handles search; this is the on-disk backup
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY

# Navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Misc
setopt INTERACTIVE_COMMENTS EXTENDED_GLOB NO_BEEP

# Emacs-style line editing — universal across remote shells
bindkey -e

# fzf-tab styling
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:kubectl_*:*' fzf-preview 'kubectl explain $word 2>/dev/null || echo no preview'
zstyle ':fzf-tab:*' fzf-flags --height=40% --reverse
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/conf.d/00-options.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add dot_config/zsh/conf.d/00-options.zsh
git commit -m "add 00-options.zsh (setopt, history, bindkey, fzf-tab styling)"
```

---

## Task 6: `conf.d/10-completions.zsh`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/conf.d/10-completions.zsh`

- [ ] **Step 1: Write the file**

```zsh
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
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/conf.d/10-completions.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add dot_config/zsh/conf.d/10-completions.zsh
git commit -m "add 10-completions.zsh (cache kubectl/helm/k9s, direct gh)"
```

---

## Task 7: `conf.d/20-aliases.zsh`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/conf.d/20-aliases.zsh`

- [ ] **Step 1: Write the file**

```zsh
# Editor
alias v=nvim vi=nvim vim=nvim

# Eza wrappers (own names — don't alias over ls)
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2'

# Bat with own name (don't alias over cat)
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

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/conf.d/20-aliases.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Behavioral smoke-test**

Run: `zsh -c 'source dot_config/zsh/conf.d/20-aliases.zsh && type k && type ll && type gst'`
Expected output (order doesn't matter):
- `k is an alias for kubectl`
- `ll is an alias for eza -l --git --group-directories-first`
- `gst is an alias for git status -sb`

- [ ] **Step 4: Commit**

```bash
git add dot_config/zsh/conf.d/20-aliases.zsh
git commit -m "add 20-aliases.zsh (editor, eza, bat, git, k8s)"
```

---

## Task 8: `conf.d/30-functions.zsh`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/conf.d/30-functions.zsh`

- [ ] **Step 1: Write the file**

```zsh
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
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/conf.d/30-functions.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Behavioral smoke-test**

Run: `zsh -c 'source dot_config/zsh/conf.d/30-functions.zsh && type mkcd && type kshell && type listening'`
Expected: each function listed as `... is a shell function from ...`.

- [ ] **Step 4: Commit**

```bash
git add dot_config/zsh/conf.d/30-functions.zsh
git commit -m "add 30-functions.zsh (kshell, klogs, jq-clip, listening, venv, mkcd, kpods)"
```

---

## Task 9: `conf.d/40-kube.zsh`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/conf.d/40-kube.zsh`

- [ ] **Step 1: Write the file**

```zsh
# kubecolor as kubectl — notes' explicit exception to "don't alias over originals"
command -v kubecolor >/dev/null && alias kubectl=kubecolor
compdef kubecolor=kubectl
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/conf.d/40-kube.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add dot_config/zsh/conf.d/40-kube.zsh
git commit -m "add 40-kube.zsh (kubecolor wraps kubectl)"
```

---

## Task 10: `conf.d/99-work.zsh.example`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/conf.d/99-work.zsh.example`

- [ ] **Step 1: Write the file**

```zsh
# Copy to 99-work.zsh and fill in.
# Gitignored — Rackspace-internal stuff lives here.
# Examples:
# export AWS_PROFILE=...
# alias ksaml='saml2aws login -a ...'
# alias kdev='kubectl --context=...'
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/conf.d/99-work.zsh.example`
Expected: no output, exit 0 (file is comments only).

- [ ] **Step 3: Commit**

```bash
git add dot_config/zsh/conf.d/99-work.zsh.example
git commit -m "add 99-work.zsh.example template (gitignored real file)"
```

---

## Task 11: Atuin config

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/atuin/config.toml`

- [ ] **Step 1: Create directory and write the file**

```bash
mkdir -p dot_config/atuin
```

```toml
filter_mode_shell_up_key_binding = "session"   # ↑ recalls within current session only
filter_mode = "global"                         # Ctrl-R searches everything
search_mode = "fuzzy"                          # fzf-style scoring; Ctrl-S in TUI to switch
# Sync (deferred):
# sync_address = "https://api.atuin.sh"
# auto_sync = true
```

- [ ] **Step 2: Validate TOML**

Run: `python3 -c "import tomllib; tomllib.loads(open('dot_config/atuin/config.toml').read()); print('OK')"`
Expected: `OK`. (If python3 < 3.11, fall back to: `python3 -c "import tomli; tomli.loads(open('dot_config/atuin/config.toml').read()); print('OK')"`.)

- [ ] **Step 3: Commit**

```bash
git add dot_config/atuin/config.toml
git commit -m "add atuin config (session filter on up, fuzzy search)"
```

---

## Task 12: Carry over `~/.p10k.zsh`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/dot_p10k.zsh` (copy of existing `~/.p10k.zsh`)

- [ ] **Step 1: Verify source exists**

Run: `[[ -f ~/.p10k.zsh ]] && wc -l ~/.p10k.zsh || echo "MISSING"`
Expected: line count (typically 1500+ lines), not "MISSING". If MISSING, run `p10k configure` first to generate one, then resume.

- [ ] **Step 2: Copy verbatim**

Run: `cp ~/.p10k.zsh dot_config/zsh/dot_p10k.zsh`

- [ ] **Step 3: Verify copy is identical and parseable**

Run: `diff -q ~/.p10k.zsh dot_config/zsh/dot_p10k.zsh && zsh -n dot_config/zsh/dot_p10k.zsh && echo OK`
Expected: `OK` with no diff output.

- [ ] **Step 4: Commit**

```bash
git add dot_config/zsh/dot_p10k.zsh
git commit -m "carry over p10k config from existing ~/.p10k.zsh"
```

---

## Task 13: Assemble `.zshrc`

**Files:**
- Create: `/Users/neelava/platform9/dotfiles/dot_config/zsh/dot_zshrc`

- [ ] **Step 1: Write the file**

```zsh
# Profiling: uncomment this and the matching `zprof` at the bottom to debug slow startup.
# zmodload zsh/zprof

# p10k instant prompt — must run before anything that prints to stdout
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Antidote: static-load — compile .zsh_plugins.txt → .zsh_plugins.zsh only when txt is newer.
# Steady-state startup just sources the precompiled file.
ANTIDOTE_HOME="${HOMEBREW_PREFIX:-/opt/homebrew}/share/antidote"
zsh_plugins="$ZDOTDIR/.zsh_plugins.zsh"
if [[ ! $zsh_plugins -nt $ZDOTDIR/.zsh_plugins.txt ]]; then
  source "$ANTIDOTE_HOME/antidote.zsh"
  antidote bundle <"$ZDOTDIR/.zsh_plugins.txt" >|"$zsh_plugins"
fi
source "$zsh_plugins"

# Powerlevel10k theme (sourced directly from brew formula — faster than via antidote)
source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/powerlevel10k/powerlevel10k.zsh-theme"

# Completion init — -C skips daily security check (cache trust assumed)
autoload -Uz compinit
compinit -C

# Source numbered conf.d/ fragments in order
for f in $ZDOTDIR/conf.d/*.zsh(N); do source "$f"; done

# Tool hooks (each guarded so missing tools don't break startup).
# Order matters: atuin must be LAST so it claims Ctrl-R from fzf.
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd z)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v fnm    >/dev/null && eval "$(fnm env --use-on-cd)"
command -v fzf    >/dev/null && source <(fzf --zsh)
command -v atuin  >/dev/null && eval "$(atuin init zsh)"

# p10k user config — sourced last
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# zprof  # paired with the zmodload at top — uncomment together when profiling
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dot_config/zsh/dot_zshrc`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add dot_config/zsh/dot_zshrc
git commit -m "add zshrc (instant prompt, antidote static-load, conf.d, hooks)"
```

---

## Task 14: End-to-end sandbox smoke test

**Goal:** Boot a clean zsh in a sandbox `$HOME` using ONLY these files, confirm no errors, benchmark startup time. No commit — verification step.

**Files:** none modified. Sandbox is created in `$(mktemp -d)`.

- [ ] **Step 1: Create the sandbox**

```bash
SANDBOX=$(mktemp -d)
echo "Sandbox: $SANDBOX"

# Mirror the chezmoi-deployed layout
mkdir -p "$SANDBOX/.config/zsh/conf.d" "$SANDBOX/.config/atuin"

cp dot_zshenv                                  "$SANDBOX/.zshenv"
cp dot_config/zsh/dot_zshenv                   "$SANDBOX/.config/zsh/.zshenv"
cp dot_config/zsh/dot_zshrc                    "$SANDBOX/.config/zsh/.zshrc"
cp dot_config/zsh/dot_zsh_plugins.txt          "$SANDBOX/.config/zsh/.zsh_plugins.txt"
cp dot_config/zsh/dot_p10k.zsh                 "$SANDBOX/.config/zsh/.p10k.zsh"
cp dot_config/zsh/conf.d/*.zsh                 "$SANDBOX/.config/zsh/conf.d/"
cp dot_config/zsh/conf.d/99-work.zsh.example   "$SANDBOX/.config/zsh/conf.d/99-work.zsh.example"
cp dot_config/atuin/config.toml                "$SANDBOX/.config/atuin/config.toml"
```

- [ ] **Step 2: Boot a sandbox shell and confirm clean exit**

```bash
HOME="$SANDBOX" ZDOTDIR="$SANDBOX/.config/zsh" zsh -i -c 'echo READY; exit'
```

Expected: outputs `READY` (possibly preceded by p10k instant-prompt output and any first-time antidote compile messages). Exit code 0. No error messages from missing tools (each is guarded by `command -v`). The `.zsh_plugins.zsh` precompiled output should now exist:

```bash
ls -la "$SANDBOX/.config/zsh/.zsh_plugins.zsh"
```

- [ ] **Step 3: Benchmark steady-state startup**

```bash
HOME="$SANDBOX" ZDOTDIR="$SANDBOX/.config/zsh" hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
```

Expected: mean under 100ms (target per spec). If between 100-200ms, acceptable for v1; flag for follow-up profiling. If >200ms, do NOT proceed — uncomment the `zprof` block in `.zshrc`, re-run, and post the top offenders for triage before declaring v1 done.

- [ ] **Step 4: Functional spot-checks inside the sandbox shell**

```bash
HOME="$SANDBOX" ZDOTDIR="$SANDBOX/.config/zsh" zsh -i -c '
  echo "ZDOTDIR=$ZDOTDIR"
  echo "EDITOR=$EDITOR"
  echo "PATH-leading: ${path[1]}"

  # Aliases
  type k        || echo "MISSING: k alias"
  type ll       || echo "MISSING: ll alias"
  type gst      || echo "MISSING: gst alias"
  type kubectl  || echo "MISSING: kubectl alias (should resolve to kubecolor)"

  # Functions
  type kshell   || echo "MISSING: kshell function"
  type mkcd     || echo "MISSING: mkcd function"
  type kpods    || echo "MISSING: kpods function"

  # Tools loaded by hooks
  command -v atuin  >/dev/null || echo "MISSING: atuin"
  command -v zoxide >/dev/null || echo "MISSING: zoxide"
  command -v direnv >/dev/null || echo "MISSING: direnv"
  command -v fnm    >/dev/null || echo "MISSING: fnm"

  # Atuin and zsh history are operational (commands return 0 even when DBs are empty)
  atuin search --limit 1 "test" >/dev/null && echo "atuin: OK" || echo "MISSING: atuin functional"
  fc -l 1 >/dev/null            && echo "history: OK"        || echo "MISSING: history functional"

  # Completion cache files were generated (kubectl/helm/k9s only)
  for tool in kubectl helm k9s; do
    [[ -f $ZDOTDIR/cache/$tool ]] && echo "cache: $tool OK" || echo "MISSING: $tool cache"
  done
'
```

Expected:
- `ZDOTDIR=<sandbox>/.config/zsh`
- `EDITOR=nvim`
- `PATH-leading:` ends with `/.local/bin`
- All 4 aliases listed (k → kubectl, ll → eza..., gst → git status..., kubectl → kubecolor)
- All 3 functions listed
- All 4 `command -v` tool checks pass
- `atuin: OK`, `history: OK`
- `cache: kubectl OK`, `cache: helm OK`, `cache: k9s OK`
- No `MISSING:` lines anywhere

- [ ] **Step 5: Clean up**

```bash
rm -rf "$SANDBOX"
echo "Sandbox cleaned."
```

- [ ] **Step 6: Push the branch (optional, only if remote is configured)**

```bash
git push -u origin dev-initial 2>&1 | tee /dev/null
```

If the remote isn't set yet or push fails because it's a public-future repo not yet created on GitHub, skip this step. The local commits are the deliverable for this scope.

---

## Acceptance criteria for the whole plan

After Task 14 succeeds:

1. All 13 source files exist in the repo at the paths in the file map above.
2. Each file passed its individual syntax check.
3. The sandbox boot in Task 14 Step 2 outputs `READY` and exits 0.
4. The hyperfine benchmark in Task 14 Step 3 reports mean steady-state under 100ms.
5. All functional spot-checks in Task 14 Step 4 pass (no MISSING lines).
6. `git log --oneline` shows ~13 new commits, none containing `Co-Authored-By: Claude`.
7. Working tree is clean (`git status` shows nothing to commit).

The actual `chezmoi apply` deploy to live `$HOME` is **out of scope for this plan** — separate flow once you're confident in the artifacts.
