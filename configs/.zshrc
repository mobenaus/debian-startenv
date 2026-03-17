# ~/.zshrc – Zsh interactive shell configuration
# Part of debian-startenv: https://github.com/mobenaus/debian-startenv

# ---- Oh My Zsh ----
export ZSH="$HOME/.oh-my-zsh"

# Theme – leave empty to use Starship instead
ZSH_THEME=""

# Plugins
plugins=(
    git
    docker
    docker-compose
    kubectl
    helm
    fzf
    zoxide
    nvm
    sdk
    tmux
    copypath
    copyfile
    dirhistory
    history
    sudo
    web-search
)

[[ -s "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# ---- History settings ----
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ---- PATH additions ----
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.sdkman/bin:$PATH"

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
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# ---- fzf ----
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
    source /usr/share/doc/fzf/examples/completion.zsh
fi

# ---- kubectl autocompletion ----
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
    compdef __start_kubectl k
fi

# ---- Helm autocompletion ----
if command -v helm &>/dev/null; then
    source <(helm completion zsh)
fi

# ---- Starship prompt ----
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
