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
