# Dev Environment Setup & Philosophy

> Personal reference compiled from extended planning conversation.
> Context: software developer working primarily with Kubernetes and Go, building an LLM inference + fine-tuning + RAG platform. Writes controllers, works with GPUs, has bash/Python background, prior OpenStack experience. Already comfortable with zsh + powerlevel10k + plugins on current work laptop. Setting up a new work laptop and wants this done deliberately.

---

## Table of Contents

1. [Guiding Philosophy](#guiding-philosophy)
2. [Shell Choice](#shell-choice)
3. [Zsh Configuration](#zsh-configuration)
4. [Terminal Multiplexer](#terminal-multiplexer)
5. [Editor Strategy](#editor-strategy)
6. [Remote / SSH / Pod Editing](#remote--ssh--pod-editing)
7. [Data & Shell Tooling](#data--shell-tooling)
8. [Better Unix Tools](#better-unix-tools)
9. [Why The New Tools Are Faster](#why-the-new-tools-are-faster)
10. [Python Tooling (uv)](#python-tooling-uv)
11. [Kubernetes Tooling](#kubernetes-tooling)
12. [SSH & Remote Work](#ssh--remote-work)
13. [Terminal Emulators](#terminal-emulators)
14. [Atuin & History](#atuin--history)
15. [Complete Tool Install List](#complete-tool-install-list)
16. [Gaps & Things Often Missed](#gaps--things-often-missed)
17. [Adoption Strategy: Tools as Extensions](#adoption-strategy-tools-as-extensions)
18. [Open Threads To Continue](#open-threads-to-continue)

---

## Guiding Philosophy

**Upgrade the tool, don't change the paradigm — at least not on the machine that pays you.**

Two tests every tool should pass one of:

- **Drop-in upgrade:** same job, faster/better, no real tradeoff. Adopt freely. (uv, fnm, ripgrep, fd, atuin, zinit, delta, etc.)
- **Universal skill:** works everywhere you go — every server, container, jump host. Pick the universal option and customize aesthetics only. (zsh, tmux, vim motions, jq, awk basics, ssh config.)

Tools that ask you to **change how you work** (nu, Helix, fish, zellij) — try on personal machine, don't bet work setup on them. The cost is ecosystem reach, muscle memory across machines, and "does this work in the prod box / container / CI runner."

Corollary principles:

- **Don't alias over the originals** (`cat`, `ls`, `grep`). Use new tools interactively, leave originals untouched for scripts and pipelines.
- **Customize aesthetics freely; keep core muscle-memory keys as defaults** so your hands work everywhere.
- **Project your environment outward** (sshfs, `nvim scp://`, debug containers) instead of installing your config on every random box.
- **One tool at a time, until it's reflexive.** Don't install 30 tools you don't use.

---

## Shell Choice

**Decision: zsh** on the new work laptop.

Reasoning: Kubernetes/Go work lives in bash-flavored snippets — kubectl one-liners, Helm scripts, NVIDIA driver setup, CUDA env exports, `curl | sh` installers. Zsh runs all of that verbatim. Fish makes you mentally translate `export FOO=bar` → `set -x FOO bar`; bad tax when debugging at 11pm. Existing zsh + p10k + autosuggestions setup already gives ~90% of fish's out-of-box experience.

- **Personal laptop:** keep playing with fish for low-stakes experimentation.
- **Nu shell:** install but **not** as login shell. Launch on demand for structured-data tasks (parsing kubectl JSON, eval CSVs, API responses). Revisit in 6 months.
- **For "force myself to use nu" without losing bash compatibility:** type `bash` to drop into a real bash subshell, exit to return. Or run `bash -c "..."` inline. Or prefix `^./script.sh` to bypass nu's parser. Sourcing bash env files: `bash -c "source ./env.sh && env" | lines | parse "{name}={value}" | transpose -r -d | load-env`.

---

## Zsh Configuration

Goal: sub-100ms startup, lean, fast.

- **Plugin manager:** zinit or antidote (NOT Oh My Zsh). Both support lazy/turbo loading — plugins load *after* the prompt appears.
- **Essential plugins only:**
  - `zsh-users/zsh-autosuggestions`
  - `zdharma-continuum/fast-syntax-highlighting` (faster than zsh-syntax-highlighting; load **last**)
  - `zsh-users/zsh-completions`
  - `Aloxaf/fzf-tab` — replaces tab completion with fzf (life-changing for kubectl/git)
- **Prompt:** keep p10k. Add **instant prompt** at the very top of `.zshrc`:

```zsh
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

- **Cache slow completions** (`kubectl`, `helm`, `k9s`, `gh`):

```zsh
[[ -f ~/.zsh/cache/kubectl ]] || kubectl completion zsh > ~/.zsh/cache/kubectl
source ~/.zsh/cache/kubectl
```

- **Lazy-load slow stuff:**
  - Replace `nvm` with `fnm` (Rust, instant)
  - Skip `pyenv` — `uv` replaces it
  - `compinit -C` if you trust your setup (skips daily security check)
- **Profile when slow:**

```zsh
# Top of .zshrc
zmodload zsh/zprof
# Bottom of .zshrc
zprof
```

- **Benchmark:** `time zsh -i -c exit`. Target: <100ms, achievable <50ms.
- **`direnv` for per-project env** instead of polluting `.zshrc`.
- **Keep `$PATH` clean** — long PATH with missing dirs slows every command lookup.

---

## Terminal Multiplexer

**Decision: tmux**, not zellij.

Reason: must work everywhere — jump hosts, exec into pods, ephemeral nodes. tmux is universal; zellij isn't installed there.

**Keep `Ctrl-b` as prefix — do not rebind.** Cognitive cost of context switching between local custom prefix and remote default prefix is worse than the ergonomic win. After a week `Ctrl-b` is fine.

Customize **aesthetics** freely (those don't transfer but don't hurt when missing). Keep **muscle-memory keys** as defaults.

Daily key list (defaults, work everywhere):

- `Ctrl-b d` — detach
- `Ctrl-b c` — new window
- `Ctrl-b n` / `p` — next/prev window
- `Ctrl-b "` / `%` — horizontal/vertical split
- `Ctrl-b o` — cycle panes
- `Ctrl-b z` — zoom pane
- `Ctrl-b [` — copy mode (vi keys if `mode-keys vi`)
- `Ctrl-b x` — kill pane

Minimum config (`~/.tmux.conf`):

```tmux
# Mouse support
set -g mouse on

# Start windows/panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Splits open in current path (don't change the keys, just behavior)
bind '"' split-window -v -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"

# Bigger scrollback
set -g history-limit 50000

# True color
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Vi mode for copy
setw -g mode-keys vi
```

Plugins via `tmux-plugins/tpm`:
- `tmux-resurrect` — save/restore sessions
- `tmux-continuum` — automatic save/restore across reboots

**zellij** on personal laptop if curious. Steal status bar / layout ideas back into tmux.

---

## Editor Strategy

Three-editor setup is fine and normal:

- **GoLand** — heavy Go work, controllers, debugging, refactoring. Don't fight what works.
- **Neovim with LazyVim** — terminal-native, quick edits, remote work, growing into primary editor over time. Bigger ecosystem than Helix, AI tooling lands here first, mature DAP/Go LSP/yaml.
- **Zed** — reading, lightweight edits, will improve over time.

**Vim motions are the universal skill.** Stay fluent so you're never stuck on a remote box with stock `vi`. This is a career skill, not a tool choice.

**Helix:** not now. Smaller ecosystem, no killer feature over LazyVim with a distro. Try on personal if curious.

**Why not Helix-as-uv-style-upgrade:** uv is a strict superset of pip with no real downside. Helix vs Neovim is a paradigm shift (selection-first vs verb-first), smaller plugin ecosystem, no equivalent DAP/AI maturity. Different category of decision.

---

## Remote / SSH / Pod Editing

**Mental flip:** project your environment outward instead of installing it everywhere.

### Jump hosts you visit regularly

- Manage dotfiles with `chezmoi` (or `yadm` / GNU `stow` / plain bash install script).
- Per-user `$HOME` means no conflicts with teammates — your `~/.config/nvim/` is yours.
- If can't `sudo apt install`: install nvim AppImage / static binary to `~/bin`, add to PATH.
- `mise` can install user-local versions of many tools.
- For full LazyVim on jump host: first launch downloads plugins to `~/.local/share/nvim/`. Needs internet egress.

### Ephemeral nodes / random boxes

Don't fight it. Two paths:

- **Stock vi/vim** for quick edits — accept defaults.
- **Edit locally, save remotely:**
  - `nvim scp://user@host//path/to/file` — full local nvim config, saves over scp
  - `sshfs user@host:/etc /mnt/host-etc` — mount remote FS, use any local tool
  - `kubectl cp pod:/path /tmp/file && nvim /tmp/file && kubectl cp /tmp/file pod:/path`

### Pods without shells (distroless / scratch / busybox)

`kubectl debug` with ephemeral container:

```bash
kubectl debug -it mypod --image=ghcr.io/you/debug:latest --target=mycontainer
```

With `--target`, you share the pod's process namespace:
- `ps auxf` sees target container's processes
- `/proc/<pid>/root/` reads target container's filesystem
- `strace -p <pid>` (needs SYS_PTRACE)
- Same network namespace — `curl localhost:8080` hits the app

Existing images:
- `nicolaka/netshoot` — canonical network debug image
- `busybox` — minimal shell only
- Build your own with dotfiles + nvim + ripgrep + jq + kubectl baked in

### Node-level debugging

```bash
kubectl debug node/mynode -it --image=ghcr.io/you/debug:latest
```

Privileged debug pod with node FS at `/host`. For kubelet logs, container runtime state, host networking.

### GPU debug image (specific to inference platform work)

```dockerfile
FROM nvidia/cuda:12.4.0-base-ubuntu24.04
RUN apt-get update && apt-get install -y \
    curl wget dnsutils iputils-ping iproute2 net-tools tcpdump \
    procps htop strace ltrace lsof psmisc \
    vim less file tree ripgrep fd-find jq nvtop \
    && rm -rf /var/lib/apt/lists/*
```

Run with NVIDIA runtime / device plugin to debug GPU pods. `nvidia-smi`, `nvtop`, DCGM tools available.

---

## Data & Shell Tooling

**Skip nu as login shell. Learn the universal toolkit:**

- `jq` — JSON. The standard. `kubectl get pods -o json | jq '.items[] | select(.status.phase=="Running") | .metadata.name'`
- `yq` (Mike Farah's Go version, **not** the Python one) — YAML
- `awk` basics — `awk '{print $2}'`, `awk -F: '{print $1}'`, simple patterns and NR. Worth ~2 hours total.
- `sed` — just `s/foo/bar/g` and `-i`. Don't go deeper.
- `grep -P` for Perl regex when needed
- `xargs` — pipeline glue
- `fzf` — interactive picker, pipe-friendly both directions

**For anything beyond a one-liner:** Python. Already known. `uv run --with pandas script.py` instantly.

**Where nu actually wins** (use on demand):
- Interactive exploration of a big unfamiliar JSON blob (table view)
- Joining data across sources
- One-off CSV/Parquet poking

**DuckDB** — ridiculously good for poking at eval result files (Parquet/CSV/JSON):

```bash
duckdb -c "select * from 'results.parquet' where score < 0.5"
```

Genuinely the killer tool for the eval workflow.

---

## Better Unix Tools

All drop-in upgrades. **Don't alias over the originals** — use under their own names. Originals stay for scripts.

| Original | Replacement | Notes |
|----------|-------------|-------|
| grep | `ripgrep` (rg) | Parallel, .gitignore-aware, SIMD |
| find | `fd` | Sane defaults, fast, parallel |
| cat | `bat` | Syntax highlighting; auto-strips when piped |
| ls | `eza` | Don't pipe ls/eza — known footgun |
| cd | `zoxide` | `z projectname` jumps |
| du | `dust` | |
| df | `duf` | |
| ps | `procs` | |
| top/htop | `bottom` (btm) or `btop` | |
| time | `hyperfine` | Proper benchmarking |
| sed (simple) | `sd` | For straightforward replacements |
| diff (git) | `delta` | Set as git pager |
| awk `{print $N}` | `choose` | `choose 0 2` instead of `awk '{print $1, $3}'` |
| curl (JSON) | `xh` | Rust httpie, fast |
| dig | `dog` | |

**Pipe behavior — what to know:**

- `rg`, `fd`, `delta`: fully drop-in. Same output format as originals.
- `bat`, `eza`: auto-strip colors and decorations when piped. Pipe-safe. But avoid piping `ls`/`eza` due to filename-with-spaces footgun — use globs or `fd`.
- Watch for ANSI escapes leaking into pipelines: use `--color=never` if needed.
- **Don't alias** `cat=bat`, `grep=rg`, `ls=eza`. Will eventually break a script. Aliases like `ll='eza -l --git'` are fine.

---

## Why The New Tools Are Faster

Not because Rust > C. C and Rust produce equivalent machine code via LLVM.

Speedups come from:

1. **Parallelism by default** — rayon makes parallel walks/searches trivial. GNU grep is single-threaded.
2. **Smarter algorithms + SIMD** — finite automata regex (no backtracking), AVX2 byte scanning.
3. **Respect `.gitignore`** — skip `node_modules/`, `target/`, `.git/`. Often the biggest "speedup" is searching less.
4. **Modern I/O** — mmap, parallel directory walks, fewer allocations.
5. **Better defaults** — UTF-8, type filtering. Reduces pipelines you'd otherwise build.
6. **No legacy POSIX baggage** — designed in 2016 not 1988.

Rust is the **enabler** (memory safety, cargo, single static binary, attracted developers willing to rewrite), not the cause. Same pattern applies to uv: it's not faster because Rust is faster than Python — it's faster because dependency resolution is a proper SAT-solver problem in parallel, while pip is naive sequential.

---

## Python Tooling (uv)

**Adopt uv fully** on the new laptop. Replaces pip + venv + pyenv + pipx + pip-tools.

### Install

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Workflows

**Manage Python versions (drop pyenv):**

```bash
uv python install 3.12 3.13
uv python pin 3.12   # in a project
```

**Project workflow:**

```bash
uv init myproject
cd myproject
uv add fastapi httpx pydantic
uv run python main.py   # auto-creates venv, installs, runs
```

Produces `pyproject.toml` and `uv.lock` (real reproducible lockfile).

**Inline-deps scripts** — killer for ops/eval/probe scripts:

```python
#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["httpx", "rich"]
# ///
import httpx
from rich import print
print(httpx.get("https://...").json())
```

Run with `./script.py`. Temporary venv, no pollution. Go-binary ergonomics for Python.

**Replace pipx:**

```bash
uv tool install ruff
uvx ruff check .   # ephemeral run, like npx
```

### Adoption rule

Don't migrate existing projects. Use uv for *new* things — within a month going back feels weird.

---

## Kubernetes Tooling

**Shell-agnostic:** k9s and helm work identically across zsh/nu/fish.

### Core CLI

- `kubectl` + completions (cached)
- `helm` + completions (cached)
- `k9s` + completions
- `kubectx` + `kubens` — context/namespace switching, **essential**
- `stern` or `kail` — multi-pod log tailing, much better than `kubectl logs`
- `kustomize`
- `kubeconform` or `kubeval` — manifest validation
- `dive` — Docker image layer inspection
- `kind` or `k3d` or `ctlptl` — local clusters for controller testing
- `krew` — kubectl plugin manager

### Krew plugins worth installing

```
kubectl krew install neat tree get-all
```

- `kubectl-neat` — strips managed fields and noise from `-o yaml`. Essential when reading manifests.
- `kubectl-tree` — ownership relationships (Deployment → ReplicaSet → Pod). Helpful for controller debugging.
- `kubectl-get-all` — find resources of all kinds.

### Quality of life

- `kubecolor` — colorize kubectl output. Alias `kubectl=kubecolor`. Pure QoL.

### Inner dev loop for controllers

- `tilt` or `skaffold` — file-watch + rebuild + redeploy. Tilt especially loved by controller devs.
- `telepresence` — run a service locally that pretends it's in-cluster.
- `kubebuilder` / `operator-sdk` + `controller-gen` — controller scaffolding.
- `air` — Go hot reload during dev.

### GitOps (if applicable)

- `flux` CLI or `argocd` CLI

### Image / supply chain

- `skopeo` — image inspection across registries
- `syft` + `grype` — SBOM and vuln scanning
- `cosign` — sign container images

### Parsing structured output (the daily idiom)

```bash
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'
helm get values mychart | yq '.image.tag'
helm template mychart | yq 'select(.kind == "Deployment") | .spec.replicas'
```

---

## SSH & Remote Work

### `~/.ssh/config` — highest-leverage thing

Spend 30 minutes on this. Pays dividends forever.

```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    # Connection multiplexing - second SSH is instant
    ControlMaster auto
    ControlPath ~/.ssh/cm/%r@%h:%p
    ControlPersist 10m
    AddKeysToAgent yes
    UseKeychain yes   # macOS only
    PreferredAuthentications publickey
    Compression yes
    HashKnownHosts yes

Host jumpbox
    HostName jump.corp.example.com
    User myname
    IdentityFile ~/.ssh/work_ed25519

Host prod-*
    User myname
    IdentityFile ~/.ssh/work_ed25519
    ProxyJump jumpbox

Host gpu-node-1
    HostName 10.0.5.42
    User root
    ProxyJump jumpbox
```

`mkdir -p ~/.ssh/cm` first time, otherwise ControlMaster fails.

### Keys

- **ed25519**, not RSA: `ssh-keygen -t ed25519 -C "your@email"`
- **Separate keys per context** — work, personal, GitHub. Don't reuse.
- `ssh-copy-id host` to push public key. Never edit `authorized_keys` manually.
- Optional: 1Password / Bitwarden SSH agent — keys in secure enclave, never on disk.

### Tunneling — daily skill for platform work

- **Local forward (`-L`)** — expose remote port locally:
  ```bash
  ssh -L 5432:db.internal:5432 jumpbox
  ```
- **Remote forward (`-R`)** — expose local port to remote:
  ```bash
  ssh -R 8080:localhost:3000 jumpbox
  ```
- **Dynamic SOCKS (`-D`)** — SSH as SOCKS proxy:
  ```bash
  ssh -D 1080 jumpbox
  ```

Practice until reflexive.

### Mosh

SSH replacement for unreliable connections. Survives network changes, suspend/resume. UDP-based session sync, local echo for instant typing.

- Install if your network allows UDP 60000-61000.
- Doesn't work through bastions cleanly, doesn't support port forwarding.
- **Mosh + tmux combo:** mosh keeps network alive, tmux keeps shell alive across reboots.

### Adjacent tools

- `autossh` — auto-reconnect SSH tunnels (if not using mosh)
- `sshfs` — mount remote FS locally, occasional use
- `rsync -avzP src/ host:/path/` — better scp, resumable, diff-only
- `croc send` / `croc <code>` — peer-to-peer file transfer through NAT
- `tailscale` — mesh VPN, "SSH everywhere without configuring it" for personal infra
- `gh` — GitHub CLI

### Secrets in dotfiles

- `age` — modern encryption, lovely
- `sops` — wraps age for k8s/yaml workflows

---

## Terminal Emulators

Performance-first, features-second, cross-platform required.

| Emulator | Notes |
|----------|-------|
| **Ghostty** | Newest, by Mitchell Hashimoto. GPU-accelerated, native everywhere, sensible defaults. **Top pick.** |
| WezTerm | Rust, GPU, multiplexer built-in, Lua-scriptable. Power-user friendly. Close second. |
| Alacritty | Rust, GPU, minimal. Pair with tmux. Fastest, most boring. |
| Kitty | GPU, image protocol, ligatures. Python config (love or hate). |

Skip: iTerm2 (slower, macOS only), Terminal.app (basic), Hyper (Electron).

**Pick:** Ghostty — same emulator on personal + work, fast, sensible defaults match philosophy.

---

## Atuin & History

`atuin` replaces shell history with SQLite-backed, searchable, syncable history.

- `Ctrl-R` becomes fuzzy-searchable across machines.
- Optional sync (their server or self-hosted).
- Tracks cwd, exit code, duration per command.
- Once you have it, you don't go back.

**Note:** can interfere with `fzf`'s `Ctrl-R`. Pick atuin — better tool.

---

## Complete Tool Install List

Organized by layer. Don't install all at once — see [Adoption Strategy](#adoption-strategy-tools-as-extensions).

### Shell layer
- zsh
- zinit or antidote
- powerlevel10k (with instant prompt)
- zsh-autosuggestions, fast-syntax-highlighting, zsh-completions, fzf-tab
- atuin
- starship (alternative to p10k — cross-shell, simpler config; otherwise stay with p10k)

### Better Unix replacements (interactive use, don't alias over originals)
- ripgrep (rg)
- fd
- bat
- eza
- delta
- dust, duf
- sd
- procs
- bottom (btm) or btop
- hyperfine
- tokei
- choose

### Navigation & search
- fzf (essential)
- zoxide
- broot (optional)

### Data & structured
- jq
- yq (Mike Farah's Go version)
- htmlq (occasional)
- miller (mlr) — CSV/TSV
- duckdb — eval/result file analysis
- gron — flatten JSON for grep
- nu — installed but on-demand

### Git
- git
- delta (above)
- lazygit
- gh
- git-absorb (auto-fixup commits, niche but lovely)
- gitleaks (pre-commit secret scanning)

### SSH / remote
- mosh (if network allows)
- rsync
- sshfs (occasional)
- croc
- tailscale (personal infra)
- autossh (if not using mosh and need persistent tunnels)

### Multiplexer
- tmux + tpm + tmux-resurrect + tmux-continuum

### Editors
- neovim (LazyVim distro)
- GoLand
- Zed
- (helix optional on personal)

### Languages / runtimes
- mise (universal version manager — replaces asdf/pyenv/nvm/rbenv) **OR** uv + fnm
- uv (Python — adopt fully)
- fnm (Node — if not using mise)
- Go (via mise or direct)

### Kubernetes
- kubectl (with cached completions)
- helm (with cached completions)
- k9s
- kubectx + kubens
- stern (or kail)
- kustomize
- kubeconform
- dive
- kind / k3d / ctlptl
- krew → kubectl-neat, kubectl-tree, kubectl-get-all
- kubecolor
- tilt (controller dev loop)
- telepresence (controller dev loop)
- kubebuilder + controller-gen
- skopeo, syft, grype, cosign (image / supply chain)
- flux or argocd CLI (if used)

### Container / build
- docker or podman
- buildx

### Networking debug (locally + in debug image)
- curl, xh (Rust httpie)
- dog (dig replacement)
- mtr
- nmap
- mitmproxy
- bandwhich (network usage by process)
- gping (graphical ping)

### Go-specific
- gopls (LSP)
- golangci-lint
- delve (dlv)
- gotestsum
- mockery
- air (hot reload)
- goreleaser (when shipping binaries)

### LLM / RAG-specific (your platform work)
- llm (Simon Willison's CLI)
- ollama (local models for testing)
- promptfoo or deepeval (eval frameworks)
- duckdb (already listed — eval result analysis)
- marimo or jupyter (exploration notebooks)

### Productivity glue
- direnv (per-dir env)
- chezmoi (dotfile management)
- age + sops (secret encryption)
- 1Password CLI (`op`) if applicable
- watchexec or entr (run on file change)
- just (better Make for task runners)
- tldr / tealdeer (`tldr tar` quick examples)
- pueue (task queue — better than `nohup &`)
- ripgrep-all (rga) — search PDFs, archives, docs
- glow (markdown render in terminal)

### AI assistants (coding)
- Claude Code (terminal-native AI agent — fits the philosophy)
- Aider (open-source CLI alternative, model-agnostic, git-native)
- Avante.nvim or CodeCompanion.nvim (Cursor-like in Neovim)
- Zed AI (already in Zed)

### Docs / notes
- Obsidian or Logseq (notes that compound)

---

## Day-One Tight Starter Set

If overwhelmed, install in this order:

1. zsh + p10k + plugins + atuin
2. Ghostty
3. tmux + minimal config
4. ripgrep, fd, bat, eza, fzf, zoxide, delta
5. uv, mise (or fnm)
6. jq, yq, kubectx, kubens, stern, k9s, lazygit
7. neovim + LazyVim
8. chezmoi (manage all of the above as you settle)
9. SSH config properly set up
10. direnv

Everything else: install when you hit the need.

---

## Gaps & Things Often Missed

### AI coding assistants
Now table-stakes for the work. Pick one terminal-based (Claude Code or aider) plus whatever's in editor.

### Observability of own dev environment
- hyperfine (benchmarking — comparing inference setups)
- bandwhich (network usage by process)
- bottom + procs (system view)
- gping (network flakiness check)

### Documentation habit
- Obsidian / Logseq for notes that compound
- A daily "lab notebook" — what tried, what worked. Pays massively for platform work where issues recur.

### Security hygiene
- gitleaks (pre-commit hook)
- trufflehog (scan repos for leaked secrets)
- syft + grype (SBOM, vulns)
- cosign (sign images)

### Browser/API debugging
- mitmproxy — intercept HTTP, capture inference API calls
- Bruno — Postman alternative, file-based, git-friendly

### Misc highly underrated
- entr / watchexec — re-run on file change
- pueue — background task queue
- ripgrep-all (rga) — search inside PDFs, archives, docs
- choose — saner `awk '{print $N}'`
- xh — Rust httpie
- gron — flatten JSON to grep-able lines

---

## Adoption Strategy: Tools as Extensions

The principle that distinguishes engineers who *use* tools well from those who *collect* them.

### Principle 1 — One tool at a time, until reflexive

Suggested 8-week ramp:

1. **Week 1:** atuin + zoxide + fzf-tab. Transforms navigation immediately.
2. **Week 2:** ripgrep + fd. Force by aliasing `grep`/`find` to error messages telling you to use the new ones (just for a week).
3. **Week 3:** lazygit. All git ops through it for a week. Decide what stays vs goes back to CLI.
4. **Week 4:** uv. Convert one Python project; use `uvx` and inline-deps for everything new.
5. **Week 5:** kubectx, kubens, stern. Compounds massively.
6. **Week 6:** tmux fluency — pick 5 keybinds you don't use, force them.
7. **Week 7:** jq + yq deep dive. 30-min jq tutorial, then jq-only for two weeks.
8. **Week 8:** Neovim daily — git commits, config edits, scratch buffers. Don't force full coding; let it grow.

After ~2 months, ~80% of productive tools are second nature.

### Principle 2 — "This is annoying — what tool would fix it?"

When tedious, pause 2 minutes: is there a tool, or a 5-line script? Most engineers either keep doing the tedious thing or yak-shave for an hour. The skill is the 2-min check.

### Principle 3 — Shell function / alias graveyard, tended quarterly

Read through `.zshrc` quarterly. Some obsolete (switched tools). Some reveal patterns (3 similar aliases → one parameterized function). Some forgotten (resurrect).

Starter functions worth having:

```zsh
# Quick pod shell
kshell() { kubectl exec -it "$1" -- ${2:-bash}; }

# Stern with sensible default
klogs() { stern --tail=100 "$@"; }

# Pretty-print clipboard JSON (mac)
jq-clip() { pbpaste | jq "${1:-.}"; }

# Show what's listening
listening() { lsof -iTCP -sTCP:LISTEN -n -P | grep LISTEN; }

# Activate uv venv in cwd
venv() { source .venv/bin/activate; }
```

### Principle 4 — Tier tools by frequency

- **Tier 1 (daily, must be reflexive):** zsh, tmux, vim motions, ripgrep, fd, fzf, jq, kubectl, git, ssh
- **Tier 2 (weekly, should be familiar):** lazygit, uv, k9s, stern, kubectx, atuin search, helm, delta
- **Tier 3 (monthly, look up when needed):** sshfs, mosh, rsync flags, awk, sed, mitmproxy, hyperfine, gron, nu
- **Tier 4 (rare, just know they exist):** croc, tailscale debug, kubectl debug syntax, age/sops, syft

Don't memorize Tier 3/4. Know they exist, look up when needed.

### Principle 5 — `~/notes/cheats.md` or navi

Personal cheatsheet for tools-you-use-but-not-daily. Every time you Google something and it takes >2min, write it down. Within 6 months, stop Googling.

Worth recording:
- jq idioms ("extract names of pods in Running state")
- tmux keybinds you use rarely
- `kubectl debug` with target syntax
- awk patterns for common log formats
- rsync flags you actually use

Cheatsheet *is* the externalized muscle memory. Re-reading converts "look up" → "know."

### Principle 6 — Pair tools with workflows, not in isolation

Don't learn `jq` abstractly. Learn it as part of "the pod inspection workflow":

```bash
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase, restarts: ([.status.containerStatuses[].restartCount] | add)}'
```

Don't learn `fzf` abstractly. Learn it as part of "switching to project I haven't touched in 3 weeks":

```
zoxide → fzf project pick → cd → lazygit to remember state
```

Tools live in workflows. Practice the flow, not the tool.

### Principle 7 — Re-evaluate quarterly, slow to remove

Audit every 3 months:
- Tools installed but unused 90 days? (Candidates for removal — slow; sometimes 6-month tools are still worth keeping.)
- Tedious things still untooled?
- Aliases never used?

Goal: stable setup. Stop adding tools after a year or two. Constantly-churning toolset = yak-shaving.

### Principle 8 — Read others' setups, sparingly

Monthly, read a "my dev setup" post or dotfiles repo. Steal one specific thing. Don't copy whole config — that's how you get a 4000-line `.zshrc` you don't understand.

Worth following: ThePrimeagen, tj devries, Mitchell Hashimoto's dotfiles, LazyVim community.

### Meta-principle

**Tools should disappear into your hands.** When you stop *thinking about* the tool and start thinking about the *thing you want to do* — extension achieved.

Path: deliberate, narrow practice. One tool, one week, used heavily, in real workflows. Not "install everything and hope."

Engineers who feel like cyborgs aren't using more tools — they're using fewer tools, deeper.

---

## Open Threads To Continue

Topics surfaced but not yet covered in depth. Pick up later:

- **Controller dev loop end-to-end:** kubebuilder + tilt + kind workflow, full setup
- **AI assistants in this stack:** which one, how to integrate (Claude Code vs aider vs nvim plugins), prompting patterns for controller code, RAG-aware coding
- **Building debug container image properly:** layered Dockerfile with general + GPU variants, registry, deployment as a personal "kubectl debug" default
- **Eval / RAG tooling angle:** DuckDB + marimo + llm CLI workflow for inference platform work, eval result inspection patterns
- **Dotfile management end-to-end with chezmoi:** from zero to fully synced across machines, including secrets via age/sops
- **Git workflow:** commit conventions, lazygit deep dive, git-absorb, worktrees for multi-branch work
- **GPU debugging tools:** nvidia-smi/nvtop/DCGM workflows, GPU-aware k8s debugging
- **Notebook workflow for exploration:** marimo vs jupyter, when to graduate from notebook to script
- **LSP and DAP setup in Neovim** for Go (when ready to make nvim primary for Go work)

---

## Quick Reference

### Benchmarking shell startup
```bash
time zsh -i -c exit
# Target: <100ms, achievable <50ms with turbo loading + p10k instant prompt
```

### Profiling slow zsh startup
```zsh
# Top of .zshrc:    zmodload zsh/zprof
# Bottom of .zshrc: zprof
# Restart shell to see breakdown
```

### Debug a distroless pod
```bash
kubectl debug -it pod-name --image=ghcr.io/you/debug:latest --target=container-name
# Then inside: ls /proc/1/root/ to see target's filesystem
```

### Edit remote file with local nvim config
```bash
nvim scp://user@host//absolute/path
```

### SSH tunnel for internal DB
```bash
ssh -L 5432:db.internal:5432 jumpbox
# Local localhost:5432 → jumpbox → db.internal:5432
```

### Inline-deps Python script
```python
#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["httpx", "rich"]
# ///
```

### Cache kubectl completions
```zsh
[[ -f ~/.zsh/cache/kubectl ]] || kubectl completion zsh > ~/.zsh/cache/kubectl
source ~/.zsh/cache/kubectl
```
