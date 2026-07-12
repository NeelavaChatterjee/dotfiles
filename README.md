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

## Fresh machine

Philosophy: the package manager owns everything it can. The only thing installed by a raw
`curl | sh` script is the package manager itself (chicken-and-egg — nothing else can install it).
Everything downstream, including chezmoi, goes through `brew`/`pacman`/`yay`/etc.

**macOS:**

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
chezmoi init --apply NeelavaChatterjee
# answer: role, headless, packagesSkip  → dotfiles applied + packages installed

# post-install (documented, run once):
eval "$(fnm env --use-on-cd)"; fnm install --lts; fnm default "$(fnm current)"; corepack enable
kubectl krew install neat oidc-login virt
exec zsh
```

**Arch Linux** (pattern only — Linux package installation isn't wired up yet, see
`packages/packages.linux` and `docs/backlog.md`; this just gets chezmoi itself onto the box):

```bash
sudo pacman -Syu --needed base-devel git
sudo pacman -S chezmoi || yay -S chezmoi   # chezmoi is in Arch's official repos; yay/AUR is the fallback
chezmoi init --apply NeelavaChatterjee
```

## Day-to-day

- **Edit config:** `chezmoi cd` drops you into the source directory — the default
  `~/.local/share/chezmoi`, the same path on every machine, so no per-machine setup is needed
  (see [Genericity](#genericity)). Edit there, `chezmoi diff` → `chezmoi apply` to test locally,
  then `git commit` + `git push` to publish.
- **Other machines:** `chezmoi update` pulls from the public upstream and applies.
- **See machine state:** `dotstatus` — role/os/headless/skip, dotfile drift, packages-vs-manifest.
- **Add a package:** add the line to the right `packages/Brewfile.*`, `chezmoi apply` (auto-installs).
- **Skip an MDM-managed app:** add its name to `packagesSkip` in `~/.config/chezmoi/chezmoi.toml`.
- **Change machine role/headless/packagesSkip** (e.g. this Mac switched from personal to work):
  either hand-edit the `[data]` block in `~/.config/chezmoi/chezmoi.toml`, or run
  `chezmoi init --prompt` to re-run the guided prompts (safe to re-run — it won't re-clone an
  existing source dir, it only regenerates the config). Either way, follow with `chezmoi apply`
  to deploy the change. Note: switching roles doesn't uninstall the old role's packages —
  see "Remove packages" below if you need to prune them.
- **Adopt a backlog tool:** `brew install <x>`; if it sticks, move it into `packages/Brewfile.*`.
- **Remove packages (manual, deliberate):**
  ```bash
  cat packages/Brewfile.common packages/Brewfile.$(chezmoi data | jq -r .role) \
    | grep -E '^(brew|cask)' | brew bundle cleanup --file=/dev/stdin   # add --force to remove
  ```

## Discipline / gotchas

- **Author only in your working checkout** (the dir your local `sourceDir` points at). Don't `chezmoi add`/`re-add` from another clone or the source and working copy will drift.
- The public repo holds **no secrets or corp-identifying config**. Corp bits live in a gitignored
  `~/.config/zsh/conf.d/99-work.zsh` and in local `chezmoi` data. Secrets stay in Keychain /
  `saml2aws` / `gh` / `twingate`.

## Genericity

Nothing machine-, user-, or org-specific is committed — so this repo works for anyone:

- **No hardcoded working-copy path.** Where you keep your editable checkout is a personal
  choice, recorded only in your local `~/.config/chezmoi/chezmoi.toml` as
  `sourceDir = "<your path>"` (never committed). If you *don't* set it, `chezmoi init <user>`
  clones to the default `~/.local/share/chezmoi` and everything still works — no separate
  checkout needed. The `~/dev/dotfiles` in this README is just an example.
- **No usernames or hostnames.** Paths use `~`/`$HOME`; anything needing the real home dir
  uses chezmoi template vars (`.chezmoi.homeDir`, `.chezmoi.username`, `.chezmoi.hostname`),
  never a literal.
- **No org/employer identifiers.** Corp-specific config lives in a gitignored
  `~/.config/zsh/conf.d/99-work.zsh` and in local (uncommitted) `chezmoi` data.
- **Per-machine differences come from data, not files.** `role` / `os` / `headless` /
  `packagesSkip` are prompted once and stored locally; the committed templates branch on them.
- **Forking:** replace `NeelavaChatterjee` in the `chezmoi init` command with your own GitHub
  handle. That's the only edit a fork needs.

## Recovery

```bash
ZDOTDIR=/tmp zsh     # bypass your config
zsh --no-rcs         # zsh with no config at all
```
Fix the offending file, `chezmoi apply`, open a new shell.

## License

MIT — see [LICENSE](./LICENSE).
