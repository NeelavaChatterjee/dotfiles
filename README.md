# dotfiles

Personal dotfiles for provisioning dev machines across contexts (work / personal) and
OSes (macOS now; Linux/VM stubbed). Managed by [chezmoi](https://www.chezmoi.io/).

**Philosophy & tool rationale:** [`dev-setup-notes.md`](./dev-setup-notes.md).
**Deferred tools (install when needed):** [`docs/backlog.md`](./docs/backlog.md).

## How it fits together

- **Machine identity** is chosen once at `chezmoi init` (`role` = work|personal, `headless`,
  and `packagesSkip`) and stored **locally** in `~/.config/chezmoi/chezmoi.toml` — never in git.
- **Config** lives as `dot_*` files (chezmoi source naming) and deploys to `$HOME`.
- **Packages** live in `packages/Brewfile.{common,work,personal}`. On `chezmoi apply`, a
  `run_onchange_` script assembles `common + <role>`, drops anything in your local
  `packagesSkip`, and runs `brew bundle`. `packages/` and `docs/` are never deployed.
- **`packagesSkip`** is how you tell brew *not* to touch apps another system (e.g. MDM) already
  owns. Add names to it in your local config; nothing machine-specific hits the public repo.

## Fresh machine (macOS)

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://get.chezmoi.io)" -- init --apply NeelavaChatterjee
# answer: role, headless, packagesSkip  → dotfiles applied + packages installed

# post-install (documented, run once):
eval "$(fnm env --use-on-cd)"; fnm install --lts; fnm default "$(fnm current)"; corepack enable
kubectl krew install neat oidc-login virt
exec zsh
```

## Day-to-day

- **Edit config:** edit in `~/dev/dotfiles`, then `chezmoi diff` → `chezmoi apply`
  (this machine's `sourceDir` points at the working tree). Push to publish to other machines.
- **Other machines:** `chezmoi update` pulls from the public upstream and applies.
- **See machine state:** `dotstatus` — role/os/headless/skip, dotfile drift, packages-vs-manifest.
- **Add a package:** add the line to the right `packages/Brewfile.*`, `chezmoi apply` (auto-installs).
- **Skip an MDM-managed app:** add its name to `packagesSkip` in `~/.config/chezmoi/chezmoi.toml`.
- **Adopt a backlog tool:** `brew install <x>`; if it sticks, move it into `packages/Brewfile.*`.
- **Remove packages (manual, deliberate):**
  ```bash
  cat packages/Brewfile.common packages/Brewfile.$(chezmoi data | jq -r .role) \
    | grep -E '^(brew|cask)' | brew bundle cleanup --file=/dev/stdin   # add --force to remove
  ```

## Discipline / gotchas

- **Author only in `~/dev/dotfiles`.** Don't `chezmoi add`/`re-add` from another clone or
  the source and working copy will drift.
- The public repo holds **no secrets or corp-identifying config**. Corp bits live in a gitignored
  `~/.config/zsh/conf.d/99-work.zsh` and in local `chezmoi` data. Secrets stay in Keychain /
  `saml2aws` / `gh` / `twingate`.

## Recovery

```bash
ZDOTDIR=/tmp zsh     # bypass your config
zsh --no-rcs         # zsh with no config at all
```
Fix the offending file, `chezmoi apply`, open a new shell.

## License

MIT — see [LICENSE](./LICENSE).
