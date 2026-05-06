# kubecolor as kubectl — notes' explicit exception to "don't alias over originals"
command -v kubecolor >/dev/null && alias kubectl=kubecolor
compdef kubecolor=kubectl
