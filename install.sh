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

if ! command -v yay &>/dev/null; then
  log_error "yay is required but not installed."
  exit 1
fi

if [[ ! -d "$HOME/.local/share/omarchy" ]]; then
  log_error "Omarchy is not installed. Please install it first and rerun."
  exit 1
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
  yay -Syu --noconfirm

  log_info "Installing base packages..."
  yay -S --noconfirm --needed base-devel git wget curl

  log_info "Installing app packages from packages.txt..."
  yay -S --noconfirm --needed - < packages.txt
}

install_vm_packages() {
  log_info "Installing VM guest packages..."
  yay -S --noconfirm --needed qemu-guest-agent spice-vdagent xf86-video-qxl
  sudo systemctl enable qemu-guest-agent
}

#---------------------------------------
# User/group setup
#---------------------------------------
setup_user() {
  log_info "Adding user '$USER' to common groups..."
  sudo usermod -aG video,audio,lp,scanner "$USER"
}

#---------------------------------------
# Directory setup
#---------------------------------------
create_directories() {
  log_info "Creating directories..."
  mkdir -p "$HOME"/{Documents,Downloads,Pictures,Videos,Music,Projects}
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
# Nautilus setup
#---------------------------------------
setup_nautilus() {
  log_info "Configuring nautilus-open-any-terminal..."
  sudo glib-compile-schemas /usr/share/glib-2.0/schemas
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal alacritty
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal keybindings '<Ctrl><Alt>t'
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal flatpak system
}

#---------------------------------------
# Hyprland setup
#---------------------------------------
setup_hyprland() {
  log_info "Adding Hyprland plugins..."
  hyprpm update
  hyprpm add https://github.com/Duckonaut/split-monitor-workspaces
  hyprpm enable split-monitor-workspaces
  hyprpm reload
}

setup_hyprland_device() {
  local device="$1"
  log_info "Linking Hyprland monitor config for $device..."

  rm -f "$HOME/.config/hypr/monitors.conf"

  case "$device" in
    desktop|vm) ln -s "$HOME/.config/hypr/monitors/desktop.conf" "$HOME/.config/hypr/monitors.conf" ;;
    laptop)     ln -s "$HOME/.config/hypr/monitors/laptop.conf"  "$HOME/.config/hypr/monitors.conf" ;;
  esac
}

#---------------------------------------
# Shell setup
#---------------------------------------
setup_shell() {
  log_info "Setting ZSH as default shell..."
  chsh -s /usr/bin/zsh
}

#---------------------------------------
# Cleanup
#---------------------------------------
cleanup_system() {
  log_info "Cleaning orphaned packages..."
  yay -Rns --noconfirm "$(pacman -Qdtq || true)"

  log_info "Removing unwanted packages..."
  yay -Rns --noconfirm ufw-docker 1password-beta 1password-cli spotify pinta obsidian signal-desktop typora xournalpp || true
}

#---------------------------------------
# Dotfiles setup
#---------------------------------------
setup_dotfiles() {
  log_info "Applying configuration files with stow..."

  # Remove conflicting configs
  local configs=(
    "$HOME/.config/alacritty"
    "$HOME/.config/hypr"
    "$HOME/.config/mpv"
    "$HOME/.config/waybar/config.jsonc"
    "$HOME/.config/wireplumber"
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
  stow -t ~ alacritty brave-flags.conf hypr mpv nvim spotify-launcher.conf waybar wireplumber .zsh .zshrc
  popd >/dev/null
}

#---------------------------------------
# Main flow
#---------------------------------------
main() {
  device=$(choose_device)
  log_info "Device type selected: $device"

  install_packages
  [[ "$device" == "vm" ]] && install_vm_packages
  setup_user
  create_directories
  setup_libvirt
  setup_nautilus
  setup_hyprland
  setup_shell
  cleanup_system
  setup_dotfiles
  setup_hyprland_device "$device"

  log_success "Installation complete! Please reboot your system."
}

main "$@"
