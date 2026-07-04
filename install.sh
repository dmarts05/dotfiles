#!/usr/bin/env bash
# This installer expects a CachyOS base installation with no desktop environment.
set -euo pipefail

#---------------------------------------
# Logging helpers
#---------------------------------------
log_info()    { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }

#---------------------------------------
# Trap for cleanup
#---------------------------------------
trap 'log_error "An unexpected error occurred. Exiting..."' ERR INT

#---------------------------------------
# Sanity checks
#---------------------------------------
if [[ "$EUID" -eq 0 ]]; then
    log_error "Please do not run this script as root."
    exit 1
fi

#---------------------------------------
# Ensure paru is installed
#---------------------------------------
if ! command -v paru &>/dev/null; then
    log_info "paru not found. Installing paru from CachyOS repositories..."
    sudo pacman -S --needed --noconfirm paru
    log_success "paru installed successfully."
fi

#---------------------------------------
# Ask device type
#---------------------------------------
choose_device() {
    local device
    read -rp "[INFO] Are you on desktop, laptop or vm? " device
    case "$device" in
        desktop|laptop|vm)
            echo "$device"
        ;;
        *)
            log_error "Invalid input. Must be 'desktop', 'laptop' or 'vm'."
            exit 1
        ;;
    esac
}

#---------------------------------------
# Package installation
#---------------------------------------
enable_multilib() {
    log_info "Enabling multilib repository..."
    sudo sed -i '/^\s*#\[multilib\]/,/^\s*#Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy --noconfirm
}

install_packages() {
    log_info "Updating and upgrading packages..."
    paru -Syu --noconfirm
    
    log_info "Installing base packages..."
    paru -S --noconfirm --needed base-devel git wget curl
    
    log_info "Installing app packages from packages.txt..."
    paru -S --noconfirm --needed - < packages.txt
}

install_vm_packages() {
    log_info "Installing VM guest packages..."
    paru -S --noconfirm --needed qemu-guest-agent spice-vdagent xf86-video-qxl
    sudo systemctl enable qemu-guest-agent
}

install_nvidia_packages() {
    log_info "Installing NVIDIA drivers and utilities..."
    paru -S --noconfirm --needed nvidia-open nvidia-utils nvidia-settings libva-nvidia-driver
    sudo systemctl enable nvidia-persistenced.service || true
}

#---------------------------------------
# Git setup
#---------------------------------------
setup_git() {
    local git_name="Daniel Martínez Sánchez"
    local git_email="danielmartinezsanchez2012@gmail.com"
    
    log_info "Configuring Git global username and email..."
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    log_info "Configuring Git to automatically set upstream when pushing..."
    git config --global push.autoSetupRemote true
    
    log_success "Git configuration complete."
}

#---------------------------------------
# User/group setup
#---------------------------------------
setup_user() {
    log_info "Adding user '$USER' to common groups..."
    sudo usermod -aG video,audio,lp,scanner,input "$USER"
}

#---------------------------------------
# Docker setup
#---------------------------------------
setup_docker() {
    log_info "Enabling Docker service..."
    sudo systemctl enable --now docker
    
    log_info "Adding user '$USER' to docker group..."
    sudo usermod -aG docker "$USER"
    
    log_success "Docker setup complete."
}

#---------------------------------------
# CUPS setup
#---------------------------------------
setup_cups() {
    log_info "Enabling CUPS printing service..."
    sudo systemctl enable --now cups
    log_success "CUPS service enabled."
}

#---------------------------------------
# Auto CPU Frequency setup
#---------------------------------------
setup_auto_cpufreq() {
    log_info "Installing auto-cpufreq for laptop power management..."
    
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$tmpdir/auto-cpufreq"
    pushd "$tmpdir/auto-cpufreq" >/dev/null
    
    if systemctl is-active --quiet auto-cpufreq.service; then
        log_info "Stopping running auto-cpufreq service..."
        sudo systemctl stop auto-cpufreq.service
    fi
    
    sudo ./auto-cpufreq-installer
    
    popd >/dev/null
    rm -rf "$tmpdir"
    
    log_success "auto-cpufreq installed and service started successfully."
}

#---------------------------------------
# Directory setup
#---------------------------------------
create_directories() {
    log_info "Creating directories..."
    mkdir -p "$HOME"/{Documents,Downloads,Pictures,Videos,Music,Projects}
    xdg-user-dirs-update
}

#---------------------------------------
# Libvirt setup
#---------------------------------------
setup_libvirt() {
    log_info "Enabling libvirt services..."
    sudo systemctl enable libvirtd virtlogd
    sudo cp -r ./replace/etc/libvirt/* /etc/libvirt/ || true
    sudo usermod -aG libvirt "$USER"
    sudo virsh net-autostart default
}

#---------------------------------------
# Limine setup
#---------------------------------------
setup_limine() {
    log_info "Configuring Limine..."

    local limine_file="/boot/limine.conf"

    if [[ ! -f "$limine_file" ]]; then
        log_info "Limine config file not found at $limine_file; skipping Limine setup."
        return 0
    fi

    if grep -Eq "^[[:space:]]*timeout:" "$limine_file"; then
        sudo sed -i 's/^[[:space:]]*timeout:.*/timeout: 1/' "$limine_file"
    else
        echo "timeout: 1" | sudo tee -a "$limine_file" >/dev/null
    fi

    log_info "Regenerating Limine entries..."
    sudo limine-mkinitcpio

    log_success "Limine configuration complete."
}

#---------------------------------------
# Login manager setup
#---------------------------------------
setup_login_manager() {
    log_info "Configuring greetd login manager..."
    sudo mkdir -p /etc/greetd /etc/pam.d /var/cache/tuigreet
    sudo cp ./replace/etc/greetd/config.toml /etc/greetd/config.toml
    sudo cp ./replace/etc/pam.d/greetd /etc/pam.d/greetd
    sudo chown greeter:greeter /var/cache/tuigreet
    sudo chmod 0755 /var/cache/tuigreet
    sudo systemctl enable greetd.service
    log_success "Login manager enabled."
}

#---------------------------------------
# Hyprland setup
#---------------------------------------
setup_hyprland_plugins() {
    log_info "Installing Hyprland Lua plugins..."

    local plugin_url="https://github.com/zjeffer/split-monitor-workspaces"
    local plugin_dir="$HOME/.config/hypr/plugins/split-monitor-workspaces"

    mkdir -p "$(dirname "$plugin_dir")"

    if [[ -d "$plugin_dir/.git" ]]; then
        log_info "Updating split-monitor-workspaces..."
        git -C "$plugin_dir" fetch -Ppft
    else
        git clone "$plugin_url" "$plugin_dir"
    fi

    local hypr_version
    hypr_version="$(hyprland --version | awk 'NR == 1 { print $2 }')"

    if [[ "$hypr_version" =~ ^0\.55\. ]]; then
        git -C "$plugin_dir" checkout release/0.55.x
        git -C "$plugin_dir" pull --ff-only
    else
        log_warn "Hyprland version '$hypr_version' is not 0.55.x; leaving split-monitor-workspaces on its current branch."
    fi

    log_success "Hyprland Lua plugin setup completed."
}

setup_hyprland_device() {
    local device="$1"
    local hypr_dir="$HOME/.config/hypr"
    local uwsm_dir="$HOME/.config/uwsm"
    local monitor_target env_target
    
    case "$device" in
        desktop|vm)
            monitor_target="$hypr_dir/monitors/desktop.lua"
            env_target="$uwsm_dir/desktop"
        ;;
        laptop)
            monitor_target="$hypr_dir/monitors/laptop.lua"
            env_target="$uwsm_dir/laptop"
        ;;
        *)
            log_error "Unknown device: $device"
            return 1
        ;;
    esac
    
    log_info "Linking Hyprland configs for $device..."
    ln -sf "$monitor_target" "$hypr_dir/monitors.lua"
    ln -sf "$env_target" "$uwsm_dir/env"
}

#---------------------------------------
# Shell setup
#---------------------------------------
setup_shell() {
    log_info "Setting ZSH as default shell..."
    chsh -s /usr/bin/zsh
}

#---------------------------------------
# Cleanup system
#---------------------------------------
cleanup_system() {
    log_info "Cleaning up orphaned packages..."
    if paru -Qtdq &>/dev/null; then
        paru -Rns --noconfirm $(paru -Qtdq)
        log_success "Removed orphaned packages."
    else
        log_info "No orphaned packages to remove."
    fi
}

#---------------------------------------
# Dotfiles setup
#---------------------------------------
setup_dotfiles() {
    log_info "Applying configuration files with stow..."
    
    local configs=(
        "$HOME/.cache/nvim"
        "$HOME/.config/Thunar"
        "$HOME/.config/alacritty"
        "$HOME/.config/autostart"
        "$HOME/.config/btop"
        "$HOME/.config/eza"
        "$HOME/.config/foot"
        "$HOME/.config/hypr"
        "$HOME/.config/kwalletrc"
        "$HOME/.config/mako"
        "$HOME/.config/mpv"
        "$HOME/.config/nvim"
        "$HOME/.config/spotify-launcher.conf"
        "$HOME/.config/swayosd"
        "$HOME/.config/tofi"
        "$HOME/.config/uwsm"
        "$HOME/.config/waybar"
        "$HOME/.config/wireplumber"
        "$HOME/.local/share/nvim"
        "$HOME/.local/state/nvim"
        "$HOME/.zsh"
        "$HOME/.zshrc"
    )

    for c in "${configs[@]}"; do
        rm -rf "$c"
    done
    
    pushd ./stow >/dev/null
    stow -t ~ alacritty autostart btop eza foot hypr kwalletrc mako mpv nvim spotify-launcher.conf swayosd thunar tofi uwsm waybar wireplumber .zsh .zshrc
    popd >/dev/null
}

#---------------------------------------
# Main flow
#---------------------------------------
main() {
    device=$(choose_device)
    log_info "Device type selected: $device"
    
    enable_multilib
    install_packages
    setup_git
    
    case "$device" in
        vm) install_vm_packages ;;
        desktop) install_nvidia_packages ;;
        laptop) setup_auto_cpufreq ;;
    esac
    
    setup_user
    setup_docker
    setup_cups
    create_directories
    setup_libvirt
    setup_limine
    setup_login_manager
    setup_shell
    cleanup_system
    setup_dotfiles
    setup_hyprland_device "$device"
    setup_hyprland_plugins
    
    log_success "Installation complete! Please reboot your system."
}

main "$@"
