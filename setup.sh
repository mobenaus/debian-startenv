#!/usr/bin/env bash
# =============================================================================
# debian-startenv - Interactive Setup Script for Debian-based Systems
# =============================================================================
# Run this script on a fresh Debian installation to configure your development
# environment.
#
# Usage: bash setup.sh
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants / Colours
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/configs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${BLUE}=== $* ===${NC}\n"; }

# Ask yes/no question – returns 0 for yes, 1 for no
confirm() {
    local prompt="${1:-Proceed?}"
    local answer
    while true; do
        read -rp "$(echo -e "${YELLOW}${prompt} [y/N]: ${NC}")" answer
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

# Run a command with sudo, prompting once if needed
sudo_run() { sudo "$@"; }

# Check if a command exists
has() { command -v "$1" &>/dev/null; }

# Ensure we are running as a normal user (not root)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. It will use sudo where needed."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# 1. OS Update
# ---------------------------------------------------------------------------
update_system() {
    header "System Update"
    info "Updating package lists and upgrading installed packages..."
    sudo_run apt-get update -y
    sudo_run apt-get upgrade -y
    sudo_run apt-get dist-upgrade -y
    sudo_run apt-get autoremove -y
    sudo_run apt-get autoclean -y
    success "System updated."
}

# ---------------------------------------------------------------------------
# 2. Basic Development Tools (no confirmation required)
# ---------------------------------------------------------------------------
install_basic_tools() {
    header "Basic Development Tools"

    # ---- APT packages ----
    local apt_packages=(
        git build-essential bash curl wget tmux mc
        python3 python3-pip net-tools openssl ca-certificates
        gnupg lsb-release
        btop fzf zsh unzip zip xz-utils fontconfig
        jq neovim
    )

    info "Installing APT packages: ${apt_packages[*]}"
    sudo_run apt-get update -y
    sudo_run apt-get install -y "${apt_packages[@]}"
    success "APT packages installed."

    # ---- zoxide ----
    if ! has zoxide; then
        info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        success "zoxide installed."
    else
        info "zoxide already installed."
    fi

    # ---- Oh My Zsh ----
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        success "Oh My Zsh installed."
    else
        info "Oh My Zsh already installed."
    fi

    # ---- Docker ----
    if ! has docker; then
        info "Installing Docker Engine..."
        sudo_run apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        sudo_run install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg \
            | sudo_run gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo_run chmod a+r /etc/apt/keyrings/docker.gpg
        local debian_codename
        debian_codename=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian ${debian_codename} stable" \
            | sudo_run tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo_run apt-get update -y
        sudo_run apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo_run usermod -aG docker "$USER"
        success "Docker installed. Log out and back in for group membership to take effect."
    else
        info "Docker already installed."
    fi

    # ---- SDKMAN ----
    if [[ ! -d "$HOME/.sdkman" ]]; then
        info "Installing SDKMAN..."
        curl -s "https://get.sdkman.io" | bash
        success "SDKMAN installed."
    else
        info "SDKMAN already installed."
    fi

    # ---- NVM ----
    if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing NVM..."
        NVM_LATEST=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash
        success "NVM ${NVM_LATEST} installed."
    else
        info "NVM already installed."
    fi

    # Source NVM into the current shell session so subsequent steps can use it
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    # ---- kubectl ----
    if ! has kubectl; then
        info "Installing kubectl..."
        KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
        curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo_run mv kubectl /usr/local/bin/kubectl
        success "kubectl ${KUBECTL_VERSION} installed."
    else
        info "kubectl already installed."
    fi

    # ---- Helm ----
    if ! has helm; then
        info "Installing Helm..."
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        success "Helm installed."
    else
        info "Helm already installed."
    fi

    # ---- k9s ----
    if ! has k9s; then
        info "Installing k9s..."
        K9S_VERSION=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSLO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
        tar -xzf k9s_Linux_amd64.tar.gz k9s
        chmod +x k9s
        sudo_run mv k9s /usr/local/bin/k9s
        rm -f k9s_Linux_amd64.tar.gz
        success "k9s ${K9S_VERSION} installed."
    else
        info "k9s already installed."
    fi

    # ---- kind ----
    if ! has kind; then
        info "Installing kind..."
        KIND_VERSION=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSLO "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64"
        chmod +x kind-linux-amd64
        sudo_run mv kind-linux-amd64 /usr/local/bin/kind
        success "kind ${KIND_VERSION} installed."
    else
        info "kind already installed."
    fi

    # ---- Tilt ----
    if ! has tilt; then
        info "Installing Tilt..."
        curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
        success "Tilt installed."
    else
        info "Tilt already installed."
    fi

    # ---- yq ----
    if ! has yq; then
        info "Installing yq..."
        YQ_VERSION=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
            -o yq_linux_amd64
        chmod +x yq_linux_amd64
        sudo_run mv yq_linux_amd64 /usr/local/bin/yq
        success "yq ${YQ_VERSION} installed."
    else
        info "yq already installed."
    fi

    # ---- lazydocker ----
    if ! has lazydocker; then
        info "Installing lazydocker..."
        LD_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/${LD_VERSION}/lazydocker_${LD_VERSION#v}_Linux_x86_64.tar.gz" \
            -o lazydocker.tar.gz
        tar -xzf lazydocker.tar.gz lazydocker
        chmod +x lazydocker
        sudo_run mv lazydocker /usr/local/bin/lazydocker
        rm -f lazydocker.tar.gz
        success "lazydocker ${LD_VERSION} installed."
    else
        info "lazydocker already installed."
    fi

    # ---- lazygit ----
    if ! has lazygit; then
        info "Installing lazygit..."
        LG_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LG_VERSION}/lazygit_${LG_VERSION#v}_Linux_x86_64.tar.gz" \
            -o lazygit.tar.gz
        tar -xzf lazygit.tar.gz lazygit
        chmod +x lazygit
        sudo_run mv lazygit /usr/local/bin/lazygit
        rm -f lazygit.tar.gz
        success "lazygit ${LG_VERSION} installed."
    else
        info "lazygit already installed."
    fi

    # ---- Starship prompt ----
    if ! has starship; then
        info "Installing Starship prompt..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
        success "Starship installed."
    else
        info "Starship already installed."
    fi

    # ---- Go ----
    if ! has go; then
        info "Installing Go..."
        GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -1)
        curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" -o go.tar.gz
        sudo_run rm -rf /usr/local/go
        sudo_run tar -C /usr/local -xzf go.tar.gz
        rm -f go.tar.gz
        # Add to PATH for this session
        export PATH="/usr/local/go/bin:$PATH"
        success "Go ${GO_VERSION} installed to /usr/local/go."
    else
        info "Go already installed: $(go version)."
    fi

    # ---- WezTerm ----
    if ! has wezterm; then
        info "Installing WezTerm..."
        curl -fsSL https://apt.fury.io/wez/gpg.key \
            | sudo_run gpg --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
        echo "deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" \
            | sudo_run tee /etc/apt/sources.list.d/wezterm.list >/dev/null
        sudo_run apt-get update -y
        sudo_run apt-get install -y wezterm
        success "WezTerm installed."
    else
        info "WezTerm already installed."
    fi

    success "All basic development tools installed."
}

# ---------------------------------------------------------------------------
# 3. IDEs (VS Code)
# ---------------------------------------------------------------------------
install_ides() {
    header "IDEs"
    if ! confirm "Install Visual Studio Code?"; then
        info "Skipping IDE installation."
        return
    fi

    if ! has code; then
        info "Installing Visual Studio Code..."
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
            | sudo_run gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
            | sudo_run tee /etc/apt/sources.list.d/vscode.list >/dev/null
        sudo_run apt-get update -y
        sudo_run apt-get install -y code
        success "Visual Studio Code installed."
    else
        info "VS Code already installed."
    fi
}

# ---------------------------------------------------------------------------
# 4. AI CLI Tools
# ---------------------------------------------------------------------------
install_ai_tools() {
    header "AI CLI Tools"
    if ! confirm "Install AI CLI tools (Gemini CLI, GitHub Copilot CLI)?"; then
        info "Skipping AI CLI tools."
        return
    fi

    # Ensure NVM is loaded in the current shell (needed when NVM was installed
    # in the same session and the shell profile has not been reloaded yet)
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    # Ensure npm/node is available (via nvm or system)
    if ! has node; then
        if has nvm; then
            info "Node.js not found. Installing LTS via NVM..."
            nvm install --lts
            nvm use --lts
        else
            error "Node.js and NVM not found. Install basic tools first (option 2)."
            return 1
        fi
    fi

    # ---- Gemini CLI ----
    if ! has gemini; then
        info "Installing Gemini CLI..."
        if ! npm install -g @google/gemini-cli; then
            warn "Could not install @google/gemini-cli."
            warn "The package name may have changed. To install manually, search for it at:"
            warn "  https://www.npmjs.com/search?q=gemini+cli"
            warn "Then run: npm install -g <package-name>"
        else
            success "Gemini CLI installed."
        fi
    else
        info "Gemini CLI already installed."
    fi

    # ---- GitHub Copilot CLI ----
    if ! has gh; then
        info "Installing GitHub CLI (required for Copilot CLI)..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo_run dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo_run chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
            | sudo_run tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo_run apt-get update -y
        sudo_run apt-get install -y gh
        success "GitHub CLI installed."
    else
        info "GitHub CLI already installed."
    fi

    info "To enable Copilot in your terminal, run: gh extension install github/gh-copilot"
    info "Then authenticate with: gh auth login"

    success "AI CLI tools installed."
}

# ---------------------------------------------------------------------------
# 5. OBS Studio & Shotcut
# ---------------------------------------------------------------------------
install_media_tools() {
    header "Media Tools (OBS Studio & Shotcut)"
    if ! confirm "Install OBS Studio and Shotcut?"; then
        info "Skipping media tools installation."
        return
    fi

    # ---- OBS Studio ----
    if ! has obs; then
        info "Installing OBS Studio..."
        if sudo_run apt-get install -y obs-studio; then
            success "OBS Studio installed via APT."
        else
            warn "obs-studio not found in default APT repos. Trying Flatpak..."
            if ! has flatpak; then
                sudo_run apt-get install -y flatpak
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            fi
            if flatpak install -y flathub com.obsproject.Studio; then
                success "OBS Studio installed via Flatpak."
            else
                error "OBS Studio installation failed. Visit https://obsproject.com/wiki/install-instructions/linux for manual instructions."
            fi
        fi
    else
        info "OBS Studio already installed."
    fi

    # ---- Shotcut ----
    if ! has shotcut; then
        info "Installing Shotcut..."
        if has flatpak; then
            flatpak install -y flathub org.shotcut.Shotcut
        else
            sudo_run apt-get install -y flatpak 2>/dev/null || true
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            flatpak install -y flathub org.shotcut.Shotcut
        fi
        success "Shotcut installed."
    else
        info "Shotcut already installed."
    fi
}

# ---------------------------------------------------------------------------
# 6. Browsers
# ---------------------------------------------------------------------------
install_browsers() {
    header "Browsers"
    if ! confirm "Install Google Chrome and Microsoft Edge?"; then
        info "Skipping browser installation."
        return
    fi

    # ---- Google Chrome ----
    if ! has google-chrome-stable && ! has google-chrome; then
        info "Installing Google Chrome..."
        curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
            -o /tmp/google-chrome.deb
        sudo_run apt-get install -y /tmp/google-chrome.deb
        rm -f /tmp/google-chrome.deb
        success "Google Chrome installed."
    else
        info "Google Chrome already installed."
    fi

    # ---- Microsoft Edge ----
    if ! has microsoft-edge-stable && ! has microsoft-edge; then
        info "Installing Microsoft Edge..."
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
            | sudo_run gpg --dearmor -o /etc/apt/keyrings/microsoft-edge.gpg
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft-edge.gpg] \
https://packages.microsoft.com/repos/edge stable main" \
            | sudo_run tee /etc/apt/sources.list.d/microsoft-edge.list >/dev/null
        sudo_run apt-get update -y
        sudo_run apt-get install -y microsoft-edge-stable
        success "Microsoft Edge installed."
    else
        info "Microsoft Edge already installed."
    fi
}

# ---------------------------------------------------------------------------
# 7. Configuration Files
# ---------------------------------------------------------------------------
install_configs() {
    header "Configuration Files"
    if ! confirm "Install dotfiles from this repository (.bashrc, .zshrc, .tmux.conf)?"; then
        info "Skipping configuration files."
        return
    fi

    if [[ ! -d "$CONFIGS_DIR" ]]; then
        error "configs/ directory not found at $CONFIGS_DIR"
        return 1
    fi

    local config_files=(
        ".bashrc"
        ".zshrc"
        ".tmux.conf"
    )

    for file in "${config_files[@]}"; do
        local src="$CONFIGS_DIR/$file"
        local dst="$HOME/$file"
        if [[ -f "$src" ]]; then
            if [[ -f "$dst" ]]; then
                info "Backing up existing $dst to ${dst}.bak"
                cp "$dst" "${dst}.bak"
            fi
            cp "$src" "$dst"
            success "Installed $file to $dst"
        else
            warn "Source file $src not found, skipping."
        fi
    done

    # ---- Starship config ----
    local starship_src="$CONFIGS_DIR/starship.toml"
    local starship_dst="$HOME/.config/starship.toml"
    if [[ -f "$starship_src" ]]; then
        mkdir -p "$HOME/.config"
        if [[ -f "$starship_dst" ]]; then
            info "Backing up existing $starship_dst to ${starship_dst}.bak"
            cp "$starship_dst" "${starship_dst}.bak"
        fi
        cp "$starship_src" "$starship_dst"
        success "Installed starship.toml to $starship_dst"
    fi

    success "Configuration files installed."
}

# ---------------------------------------------------------------------------
# 8. Git Configuration & SSH Key
# ---------------------------------------------------------------------------
setup_git() {
    header "Git Configuration & SSH Key"
    if ! confirm "Configure Git (name, email) and set up SSH key for GitHub?"; then
        info "Skipping Git configuration."
        return
    fi

    # ---- Git user name ----
    local current_name
    current_name=$(git config --global user.name 2>/dev/null || true)
    if [[ -n "$current_name" ]]; then
        info "Current Git user.name: $current_name"
        if confirm "Change Git user name?"; then
            read -rp "Enter your full name: " git_name
            git config --global user.name "$git_name"
            success "Git user.name set to: $git_name"
        fi
    else
        read -rp "Enter your full name for Git: " git_name
        git config --global user.name "$git_name"
        success "Git user.name set to: $git_name"
    fi

    # ---- Git user email ----
    local current_email
    current_email=$(git config --global user.email 2>/dev/null || true)
    if [[ -n "$current_email" ]]; then
        info "Current Git user.email: $current_email"
        if confirm "Change Git user email?"; then
            read -rp "Enter your email: " git_email
            git config --global user.email "$git_email"
            success "Git user.email set to: $git_email"
        fi
    else
        read -rp "Enter your email for Git: " git_email
        git config --global user.email "$git_email"
        success "Git user.email set to: $git_email"
    fi

    # ---- Default branch ----
    git config --global init.defaultBranch main
    git config --global core.editor "${EDITOR:-nvim}"
    git config --global pull.rebase false

    # ---- SSH Key ----
    local ssh_key="$HOME/.ssh/id_ed25519"
    if [[ -f "$ssh_key" ]]; then
        info "SSH key already exists at $ssh_key"
        info "Your public key:"
        cat "${ssh_key}.pub"
    else
        if confirm "Generate a new SSH key for GitHub?"; then
            local ssh_email
            ssh_email=$(git config --global user.email 2>/dev/null || true)
            if [[ -z "$ssh_email" ]]; then
                read -rp "Enter email for SSH key: " ssh_email
            fi
            mkdir -p "$HOME/.ssh"
            chmod 700 "$HOME/.ssh"
            ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_key" -N ""
            eval "$(ssh-agent -s)"
            ssh-add "$ssh_key"
            success "SSH key generated."
            echo ""
            info "Add the following public key to your GitHub account:"
            info "  https://github.com/settings/ssh/new"
            echo ""
            echo -e "${BOLD}"
            cat "${ssh_key}.pub"
            echo -e "${NC}"
        fi
    fi

    success "Git configuration complete."
}

# ---------------------------------------------------------------------------
# Main Menu
# ---------------------------------------------------------------------------
show_menu() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║    debian-startenv – Setup Script        ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}1)${NC} Update the operating system"
    echo -e "  ${BOLD}2)${NC} Install basic development tools (no confirmation)"
    echo -e "  ${BOLD}3)${NC} Install IDEs (VS Code)"
    echo -e "  ${BOLD}4)${NC} Install AI CLI tools (Gemini, GitHub Copilot)"
    echo -e "  ${BOLD}5)${NC} Install media tools (OBS Studio & Shotcut)"
    echo -e "  ${BOLD}6)${NC} Install browsers (Chrome & Edge)"
    echo -e "  ${BOLD}7)${NC} Install configuration files (dotfiles)"
    echo -e "  ${BOLD}8)${NC} Configure Git & SSH key"
    echo -e "  ${BOLD}9)${NC} Run all steps"
    echo -e "  ${BOLD}0)${NC} Exit"
    echo ""
}

run_all() {
    update_system
    install_basic_tools
    install_ides
    install_ai_tools
    install_media_tools
    install_browsers
    install_configs
    setup_git
}

main() {
    check_not_root

    # Ensure sudo is cached upfront
    sudo -v

    while true; do
        show_menu
        read -rp "$(echo -e "${YELLOW}Select an option [0-9]: ${NC}")" choice
        echo ""
        case "$choice" in
            1) update_system ;;
            2) install_basic_tools ;;
            3) install_ides ;;
            4) install_ai_tools ;;
            5) install_media_tools ;;
            6) install_browsers ;;
            7) install_configs ;;
            8) setup_git ;;
            9) run_all ;;
            0)
                success "Exiting. Enjoy your new environment! 🚀"
                exit 0
                ;;
            *)
                warn "Invalid option. Please choose between 0 and 9."
                ;;
        esac
        echo ""
        read -rp "$(echo -e "${CYAN}Press Enter to return to the menu...${NC}")" _
    done
}

main "$@"
