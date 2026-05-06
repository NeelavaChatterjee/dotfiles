# dotfiles

Personal dotfiles for provisioning macOS development machines. Linux variant TBD.

Managed by [chezmoi](https://www.chezmoi.io/) with files using its `dot_*` source naming. Tooling install manifest in [`Brewfile`](./Brewfile). Tooling philosophy and the rationale behind tool picks lives in [`dev-setup-notes.md`](./dev-setup-notes.md) — read first if you want the *why*.

## What's in here

- **`Brewfile`** — every CLI tool, app cask, and tap I rely on. Driven by `brew bundle install`.
- **`dot_zshenv`** + **`dot_config/zsh/`** — modular zsh layout: bootstrap that sets `ZDOTDIR=$HOME/.config/zsh`, real env file, antidote-managed plugins (lean: 4 essentials), p10k prompt, and numbered `conf.d/*.zsh` fragments for options/completions/aliases/functions/k8s.
- **`dot_config/atuin/config.toml`** — atuin owns Ctrl-R + ↑ with fuzzy search, session-filtered up-arrow.
- **`dev-setup-notes.md`** — the long-form philosophy doc.

The shell config targets sub-100ms steady-state startup using antidote's static-load pattern + p10k instant prompt + cached completions.

## Getting started on a fresh mac

```bash
# 1. Xcode CLI tools
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. chezmoi: clone + apply this repo as the source of truth for $HOME
brew install chezmoi
chezmoi init https://github.com/NeelavaChatterjee/dotfiles
chezmoi apply

# 4. brew bundle: install everything from the Brewfile that just got deployed
brew bundle install --file=~/platform9/dotfiles/Brewfile

# 5. fnm (Node) + corepack (yarn/pnpm shim)
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default "$(fnm current)"
corepack enable

# 6. krew kubectl plugins (krew binary itself is in the Brewfile)
kubectl krew install neat oidc-login virt

# 7. New shell — config is live
exec zsh
```

That's it. Open a new terminal and you should land on a p10k prompt with the new aliases, atuin Ctrl-R, etc.

### If you forked this

- Replace the `chezmoi init` URL with your own fork.
- Optionally, rename the path the Brewfile is loaded from. The `HOMEBREW_BUNDLE_FILE` export in `dot_config/zsh/dot_zshenv` points at `$HOME/platform9/dotfiles/Brewfile` — adjust to wherever you keep the repo.
- Anything corp-specific belongs in `~/.config/zsh/conf.d/99-work.zsh` (gitignored). A template lives at `99-work.zsh.example` to copy from.

## Day-to-day

- **Edit a config file:** edit it directly in `~/platform9/dotfiles/`, then `chezmoi apply` to push to `$HOME`. Or edit the deployed file and run `chezmoi re-add` to pull it back into the source.
- **Diff before applying:** `chezmoi diff` — shows what `apply` would change.
- **Update tools:** `brew bundle install` (idempotent — picks up additions). `brew bundle cleanup --file=Brewfile` lists removals; add `--force` to actually remove.
- **Profile slow zsh startup:** uncomment the `zmodload zsh/zprof` block at the top and bottom of `dot_config/zsh/dot_zshrc`, restart shell, post-mortem.

## Recovery

If a config edit breaks your shell:

```bash
# In any working terminal:
ZDOTDIR=/tmp zsh           # bypasses your config

# From SSH or recovery:
zsh --no-rcs               # zsh with NO config files at all
```

Then fix the offending file, run `chezmoi apply`, open a new shell.

## License

MIT — see [LICENSE](./LICENSE).
