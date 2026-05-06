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
