#!/usr/bin/env bash
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
# Ensure paru-bin is installed
#---------------------------------------
if ! command -v paru &>/dev/null; then
  log_info "paru not found. Installing paru-bin from AUR..."
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
  pushd /tmp/paru-bin >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf /tmp/paru-bin
  log_success "paru-bin installed successfully."
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
  paru -S --noconfirm --needed nvidia nvidia-utils nvidia-settings
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
  sudo usermod -aG video,audio,lp,scanner "$USER"
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
}

#---------------------------------------
# GRUB setup
#---------------------------------------
setup_grub() {
  log_info "Configuring GRUB..."

  local grub_file="/etc/default/grub"

  if [[ -f "$grub_file" ]]; then
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' "$grub_file"
    if grep -q "^#GRUB_DISABLE_OS_PROBER=true" "$grub_file"; then
      sudo sed -i 's/^#GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' "$grub_file"
    elif ! grep -q "GRUB_DISABLE_OS_PROBER=" "$grub_file"; then
      echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a "$grub_file" >/dev/null
    fi

    log_info "Updating GRUB configuration..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  else
    log_error "GRUB config file not found at $grub_file"
  fi

  log_info "Enabling cron and grub-btrfs services..."
  sudo systemctl enable cronie
  sudo systemctl enable grub-btrfsd

  log_success "GRUB configuration complete."
}

#---------------------------------------
# Login manager setup
#---------------------------------------
setup_login_manager() {
  log_info "Enabling login manager..."
  sudo systemctl enable ly
  log_success "Login manager enabled."
}

#---------------------------------------
# Hyprland setup
#---------------------------------------
setup_hyprland_plugins() {
  log_info "Adding Hyprland plugins..."
  hyprpm update
  hyprpm add https://github.com/Duckonaut/split-monitor-workspaces
  hyprpm enable split-monitor-workspaces
  hyprpm reload
}

setup_hyprland_device() {
  local device="$1"
  local hypr_dir="$HOME/.config/hypr"
  local monitor_target env_target

  case "$device" in
    desktop|vm)
      monitor_target="$hypr_dir/monitors/desktop.conf"
      env_target="$hypr_dir/envs/desktop.conf"
      ;;
    laptop)
      monitor_target="$hypr_dir/monitors/laptop.conf"
      env_target="$hypr_dir/envs/laptop.conf"
      ;;
    *)
      log_error "Unknown device: $device"
      return 1
      ;;
  esac

  log_info "Linking Hyprland configs for $device..."
  ln -sf "$monitor_target" "$hypr_dir/monitors.conf"
  ln -sf "$env_target" "$hypr_dir/envs.conf"
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
    "$HOME/.config/hypr"
    "$HOME/.config/mpv"
    "$HOME/.config/waybar"
    "$HOME/.config/wireplumber"
    "$HOME/.config/foot"
    "$HOME/.config/kwalletrc"
    "$HOME/.config/mako"
    "$HOME/.config/swayosd"
    "$HOME/.config/Thunar"
    "$HOME/.config/tofi"
    "$HOME/.config/eza"
    "$HOME/.zsh"
    "$HOME/.zshrc"
    "$HOME/.config/nvim"
    "$HOME/.local/share/nvim"
    "$HOME/.local/state/nvim"
    "$HOME/.cache/nvim"
    "$HOME/.config/spotify-launcher.conf"
    "$HOME/.config/brave-flags.conf"
  )
  for c in "${configs[@]}"; do
    rm -rf "$c"
  done

  pushd ./stow >/dev/null
  stow -t ~ brave-flags.conf eza foot kwalletrc hypr mako mpv nvim spotify-launcher.conf swayosd thunar tofi waybar wireplumber .zsh .zshrc
  popd >/dev/null
}

#---------------------------------------
# Main flow
#---------------------------------------
main() {
  device=$(choose_device)
  log_info "Device type selected: $device"

  install_packages
  setup_git

  case "$device" in
    vm) install_vm_packages ;;
    desktop) install_nvidia_packages ;;
  esac

  setup_user
  setup_docker
  setup_cups
  create_directories
  setup_libvirt
  setup_grub
  setup_login_manager
  setup_shell
  cleanup_system
  setup_dotfiles
  setup_hyprland_device "$device"
  setup_hyprland_plugins

  log_success "Installation complete! Please reboot your system."
}

main "$@"
