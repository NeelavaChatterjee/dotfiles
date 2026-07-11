# Tool Backlog — install when you hit the need

Not installed by default. One-at-a-time adoption: when a real need shows up, install it,
live with it until it's reflexive, then decide if it earns a place in `packages/Brewfile.*`.
`brew install <name>` unless noted. See `dev-setup-notes.md` for the adoption philosophy.

## Better-unix (nice-to-have upgrades)
- `dust` — better `du` (disk usage tree).
- `duf` — better `df` (mounts overview).
- `procs` — better `ps`.
- `sd` — simpler `sed` for straight find/replace.
- `choose` — saner `awk '{print $N}'`.
- `tokei` — fast lines-of-code counter.
- `hyperfine` — proper CLI benchmarking; when comparing command/setup speeds.
- `glow` — render markdown in the terminal.
- `tree` — directory tree (you already have `eza --tree` / `lt`).

## System monitors (btop is the default; these are alternates)
- `bottom` (`btm`) — charts-style monitor.
- `htop` — classic; muscle memory.

## Structured data (on-demand exploration)
- `duckdb` — SQL over Parquet/CSV/JSON; killer for eval-result files.
- `miller` (`mlr`) — awk/cut/join for CSV/TSV/JSON with named fields.
- `gron` — flatten JSON to greppable lines when you don't know the jq path.
- `nushell` — structured-data shell; launch on demand, not as login shell.

## Secrets / supply-chain (know they exist; install per task)
- `age` — modern file encryption.
- `sops` — encrypt secrets in YAML/JSON (wraps age).
- `cosign` — sign/verify container images.
- `syft` — generate SBOMs from images.
- `grype` — scan images for CVEs.
- `skopeo` — inspect/copy images across registries.
- `dive` — inspect Docker image layers.
- `gitleaks` — scan repo/commits for leaked secrets (pre-commit).

## Kubernetes
- `kubeconform` — validate manifests against k8s/CRD schemas (CI/pre-commit).

## SSH / remote
- `mosh` — resilient SSH over flaky networks.
- `croc` — peer-to-peer file transfer through NAT.

## File-watch
- `watchexec` — run a command on file change.
- `entr` — smaller file-watch alternative.

## Git extras
- `lazygit` — TUI for git (you currently prefer raw CLI + worktrees).
- `git-absorb` — auto-generate `fixup!` commits into the right ancestor.

## Networking debug
- `bandwhich` — live network usage by process.
- `mtr` — traceroute + ping combined.
- `gping` — ping with a realtime graph.
- `doggo` — better `dig`.
- `xh` — Rust HTTPie; fast HTTP client.

## Cloud / work (install when the work needs it)
- `awscli` — AWS CLI.
- `azure-cli` — Azure CLI.
- `saml2aws` — SAML SSO → AWS creds.
- `eksctl` — AWS EKS cluster CLI.
- `ansible` — config management / playbooks.
- `jira-cli` — superseded by `acli`; install only if you want the alternative.
- `go-swagger` (`brew install go-swagger/go-swagger/go-swagger`) — OpenAPI codegen for Go.

## AI experiments
- `windsurf` (cask) — AI editor (Codeium).
- `devin-desktop` (cask) — Devin AI desktop app.

## Misc
- `watch` — re-run a command on an interval (note: `kubectl get -w` / k9s often replace it).
- `tealdeer` (`tldr`) — community cheat-sheets: `tldr <cmd>`.
- `just` — command runner for projects with a `justfile`.
- `poppler` — PDF utilities (`pdftotext`, etc.).
