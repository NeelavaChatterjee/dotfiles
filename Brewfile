# Brewfile — dotfiles tooling manifest (macOS)
#
# Install:    brew bundle install --file=Brewfile
# Diff:       brew bundle check --file=Brewfile --verbose
# Cleanup:    brew bundle cleanup --file=Brewfile --force   # destructive: removes anything not listed
#
# Source of truth: ./dev-setup-notes.md (sections below mirror it).
# Linux variant deferred.

# ===== Taps =====
tap "homebrew/bundle"
tap "go-swagger/go-swagger"

# ===== Shell layer =====
brew "zsh"                                  # newer than macOS-bundled zsh
brew "antidote"                             # zsh plugin manager (replaces oh-my-zsh)
brew "powerlevel10k"                        # prompt; previously installed via OMZ theme
brew "atuin"                                # SQLite-backed, searchable shell history (Ctrl-R upgrade)
brew "direnv"                               # per-directory env vars; auto-loads .envrc
brew "fzf"                                  # fuzzy finder; piped picker for everything
brew "zoxide"                               # smarter cd: 'z projectname' jumps by frecency
brew "fnm"                                  # Node version manager (Rust); replaces brew node + nvm

# ===== Better Unix replacements =====
brew "ripgrep"                              # rg — parallel, .gitignore-aware grep
brew "fd"                                   # better find with sane defaults
brew "bat"                                  # cat with syntax highlighting; pipe-safe
brew "eza"                                  # better ls (don't pipe; use globs/fd)
brew "git-delta"                            # better git diffs; set as git pager
brew "dust"                                 # better du
brew "duf"                                  # better df
brew "sd"                                   # simple sed-style find/replace
brew "procs"                                # better ps
brew "bottom"                               # btm — htop-style with charts
brew "btop"                                 # alternate top, prettier
brew "htop"                                 # classic, kept for muscle memory
brew "hyperfine"                            # proper CLI benchmarking (replaces 'time')
brew "tokei"                                # fast lines-of-code counter
brew "choose"                               # saner awk '{print $N}' — `choose 0 2`
brew "tree"                                 # directory tree view
brew "watch"                                # repeat command on interval

# ===== Data & structured =====
brew "jq"                                   # JSON processor — the standard
brew "yq"                                   # YAML processor (Mike Farah's Go version)
brew "duckdb"                               # in-process SQL on Parquet/CSV/JSON; eval workflow killer
brew "gron"                                 # flatten JSON to grep-able lines
brew "miller"                               # mlr — CSV/TSV swiss army knife
brew "nushell"                              # nu — structured shell, on-demand only (not login shell)

# ===== Git =====
brew "git"
brew "git-filter-repo"                      # rewrite git history (kept)
brew "gh"                                   # GitHub CLI
brew "lazygit"                              # TUI for git
brew "gitleaks"                             # scan repo/commits for leaked secrets
brew "git-absorb"                           # auto-fixup commits into the right ancestor

# ===== SSH / remote =====
brew "mosh"                                 # SSH alternative for unreliable networks
brew "croc"                                 # peer-to-peer file transfer through NAT
brew "rsync"                                # newer than macOS system rsync

# ===== Multiplexer =====
brew "tmux"
# tpm + tmux-resurrect + tmux-continuum are git-cloned, not brew

# ===== Editors / parsers =====
brew "neovim"
brew "helix"                                # alternative editor; user trying it out
brew "lua"                                  # required by some nvim/helix configs
brew "tree-sitter-cli"                      # tree-sitter parser CLI

# ===== Languages / runtimes =====
brew "go"
brew "uv"                                   # all Python (replaces pip/venv/pyenv/pipx)
# Node: via fnm above. Yarn/pnpm: via corepack after first fnm Node install.
# Python: brew python@3.x deps will be pulled as needed by other formulae.

# ===== Kubernetes =====
brew "kubernetes-cli"                       # kubectl
brew "helm"
brew "k9s"                                  # cluster TUI
brew "kind"                                 # local k8s in containers
brew "kubectx"                              # contexts + kubens (namespaces)
brew "kustomize"
brew "kubebuilder"                          # operator/controller scaffolding
brew "kubecolor"                            # colorize kubectl output
brew "kubeconform"                          # validate manifests against schemas
brew "stern"                                # multi-pod log tailing
brew "dive"                                 # inspect Docker image layers
brew "krew"                                 # kubectl plugin manager (was via curl|sh)
brew "skopeo"                               # inspect/copy images across registries
brew "syft"                                 # generate SBOMs from images
brew "grype"                                # scan images for known CVEs
brew "cosign"                               # sign and verify container images
brew "eksctl"                               # AWS EKS CLI (kept)

# ===== Networking debug =====
brew "xh"                                   # Rust httpie; fast HTTP client
brew "doggo"                                # better dig
brew "mtr"                                  # traceroute + ping combined
brew "bandwhich"                            # network usage by process
brew "gping"                                # ping with realtime graph

# ===== Go-specific =====
brew "gopls"                                # Go LSP (moved from `go install`)
brew "delve"                                # dlv — Go debugger (moved from `go install`)
brew "staticcheck"                          # Go linter (moved from `go install`)
brew "sqlc"                                 # generate type-safe Go from SQL (moved from `go install`)
brew "golangci-lint"                        # meta-linter (kept)
brew "gotestsum"                            # better go test output and CI summaries
# mockgen stays via `go install` per user choice. mockery skipped.

# ===== Productivity =====
brew "chezmoi"                              # dotfile manager (will use to deploy this repo)
brew "age"                                  # modern encryption (small, lovely)
brew "sops"                                 # encrypt secrets in YAML/JSON; wraps age
brew "watchexec"                            # run command on file change
brew "entr"                                 # smaller alternative to watchexec
brew "just"                                 # better Make; per-project task runner
brew "tealdeer"                             # tldr — quick command examples
brew "glow"                                 # render markdown in terminal

# ===== Work / cloud (kept) =====
brew "ansible"
brew "awscli"
brew "azure-cli"
brew "openstackclient"
brew "saml2aws"                             # SAML auth flow for AWS (corp SSO)
brew "temporal"                             # Temporal workflow engine CLI

# ===== Misc / kept =====
brew "pkgconf"                              # build dep for many formulae
brew "qemu"                                 # VM emulator
brew "telnet"                               # legacy network testing
brew "mpv"                                  # media player CLI
brew "cmatrix"                              # the screensaver
brew "opencode"                             # AI coding agent (alternative to Claude Code)

# ===== Tap-sourced =====
brew "go-swagger/go-swagger/go-swagger"     # OpenAPI codegen for Go

# ===== Casks: dev environment =====
cask "ghostty"                              # terminal emulator (top pick per notes)
cask "goland"                               # JetBrains Go IDE
cask "zed"                                  # fast editor (Rust)
cask "windsurf"                             # AI editor
cask "claude"                               # Claude desktop app
cask "claude-code"                          # Claude Code (cask installer)
cask "orbstack"                             # Docker + k8s on macOS

# ===== Casks: browsers =====
cask "brave-browser"
cask "google-chrome"
cask "thebrowsercompany-dia"                # Dia browser
cask "zen"                                  # Zen browser

# ===== Casks: comms & collab =====
cask "slack"
cask "microsoft-teams"
cask "zoom"
cask "google-drive"

# ===== Casks: notes / docs =====
cask "obsidian"                             # notes that compound (NEW)

# ===== Casks: utilities =====
cask "stats"                                # macOS menu-bar system stats
cask "unnaturalscrollwheels"                # natural scroll on trackpad only
cask "twingate"                             # corp zero-trust VPN
cask "localsend"                            # local-network file transfer
cask "hoppscotch"                           # API client (Postman alternative)
cask "keeweb"                               # KeePass-format password manager
cask "vlc"
cask "stolendata-mpv"                       # mpv with macOS-native UI
cask "spotify"
