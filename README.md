# debian-startenv

Scripts and dotfiles for a development environment based on Debian.

## Quick Start

Clone this repository and run the interactive setup script:

```bash
git clone https://github.com/mobenaus/debian-startenv.git
cd debian-startenv
chmod +x setup.sh
bash setup.sh
```

> **Note:** Do **not** run as root. The script will prompt for `sudo` when needed.

---

## Menu Options

| # | Option | Confirmation required? |
|---|--------|----------------------|
| 1 | Update the operating system | No |
| 2 | Install basic development tools | **No** (installs automatically) |
| 3 | Install IDEs (VS Code) | Yes |
| 4 | Install AI CLI tools (Gemini, GitHub Copilot) | Yes |
| 5 | Install media tools (OBS Studio & Shotcut) | Yes |
| 6 | Install browsers (Google Chrome & Microsoft Edge) | Yes |
| 7 | Install configuration files (dotfiles) | Yes |
| 8 | Configure Git (name/email) & generate SSH key | Yes |
| 9 | Run all steps | — |
| 0 | Exit | — |

---

## Basic Development Tools (option 2)

The following tools are installed automatically without prompting:

| Category | Tools |
|----------|-------|
| Shell | zsh, oh-my-zsh, bash, starship |
| Terminal multiplexer | tmux |
| File manager | mc |
| Network / HTTP | curl, wget, net-tools, openssl |
| Build / Compiler | build-essential, git |
| Python | python3, python3-pip |
| System monitor | btop |
| Fuzzy finder | fzf, zoxide |
| Editor | neovim |
| Misc | jq, yq |
| Runtime managers | nvm (Node.js), sdkman (JVM) |
| Go | go (latest) |
| Container | docker, lazydocker |
| Kubernetes | kubectl, helm, k9s, kind, tilt |
| Git UI | lazygit |
| Terminal emulator | WezTerm |

---

## Configuration Files

Dotfiles are stored in the `configs/` directory:

| File | Destination |
|------|-------------|
| `configs/.bashrc` | `~/.bashrc` |
| `configs/.zshrc` | `~/.zshrc` |
| `configs/.tmux.conf` | `~/.tmux.conf` |
| `configs/starship.toml` | `~/.config/starship.toml` |

Existing files are automatically backed up with a `.bak` extension before being replaced.

---

## Git & SSH Setup (option 8)

- Prompts for your name and email and writes them to `~/.gitconfig`.
- Sets `main` as the default branch name.
- Generates an **Ed25519** SSH key if one does not already exist and prints
  the public key so you can add it to your GitHub account at
  <https://github.com/settings/ssh/new>.
