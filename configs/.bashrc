# ~/.bashrc – Bash interactive shell configuration
# Part of debian-startenv: https://github.com/mobenaus/debian-startenv

# ---- Do nothing if not running interactively ----
[[ $- != *i* ]] && return

# ---- History settings ----
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize

# ---- Less colours ----
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# ---- PATH additions ----
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# ---- Editor ----
export EDITOR=nvim
export VISUAL=nvim

# ---- Aliases – navigation ----
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lAh --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# ---- Aliases – git ----
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias lg='lazygit'

# ---- Aliases – docker ----
alias dk='docker'
alias dkc='docker compose'
alias lzd='lazydocker'

# ---- Aliases – kubernetes ----
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config use-context'

# ---- Aliases – editors / tools ----
alias vim='nvim'
alias vi='nvim'
alias cat='bat 2>/dev/null || cat'

# ---- NVM ----
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# ---- SDKMAN ----
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# ---- zoxide (smarter cd) ----
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi

# ---- fzf ----
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash 2>/dev/null || true)"
fi

# ---- kubectl autocompletion ----
if command -v kubectl &>/dev/null; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
fi

# ---- Helm autocompletion ----
if command -v helm &>/dev/null; then
    source <(helm completion bash)
fi

# ---- Starship prompt ----
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
