#!/bin/bash

# Check if user is root
if [ "$EUID" -eq 0 ]; then
  echo "[ERROR] Please do not run this script as root, exiting..."
  exit
fi

# Install Omarchy (only if not already installed)
if [ ! -d "$HOME/.local/share/omarchy" ]; then
  echo "[INFO] Omarchy not found, installing..."
  echo "[INFO] Once Omarchy finishes installing (and possibly reboots),"
  echo "[INFO] you will need to rerun this script to continue setup."
  wget -qO- https://omarchy.org/install-bare | bash
  exit 0
else
  echo "[INFO] Omarchy already installed, skipping..."
fi

# Ask user if we are on deskop, laptop or vm
echo "[INFO] Are you on desktop, laptop or vm?"
read -r device
if [[ "$device" != "desktop" && "$device" != "laptop" && "$device" != "vm" ]]; then
  echo "[ERROR] Please, enter desktop or laptop, exiting..."
  exit
fi

echo "[INFO] Starting installation..."

# Update and upgrade packages
echo "[INFO] Updating and upgrading packages..."
yay -Syu --noconfirm

# Install basic packages for installation
echo "[INFO] Installing basic packages..."
yay -S --noconfirm --needed base-devel git wget curl

# Install app packages
echo "[INFO] Installing app packages..."
yay -S --noconfirm --needed - <packages.txt

# Install virtualization guest packages if running inside a VM
if [ "$device" = "vm" ]; then
  echo "[INFO] Installing virtualization guest packages..."
  yay -S --noconfirm --needed qemu-guest-agent spice-vdagent xf86-video-qxl

  echo "[INFO] Enabling QEMU guest agent..."
  sudo systemctl enable qemu-guest-agent
fi

# Set general user groups
echo "[INFO] Setting general user groups..."
sudo usermod -aG video,audio,lp,scanner $USER

# Create directories
echo "[INFO] Creating directories..."
mkdir -p {~/Documents,~/Downloads,~/Pictures,~/Videos,~/Music,~/Projects}

# Set up libvirt
sudo systemctl enable libvirtd
sudo systemctl enable virtlogd
sudo cp -r ./replace/etc/libvirt/* /etc/libvirt/
sudo usermod -aG libvirt $USER

# Set up nautilus open any terminal extension
sudo glib-compile-schemas /usr/share/glib-2.0/schemas
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal alacritty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal keybindings '<Ctrl><Alt>t'
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal flatpak system

# Add Hyprland plugins
hyprpm update
hyprpm add https://github.com/Duckonaut/split-monitor-workspaces
hyprpm enable split-monitor-workspaces
hyprpm reload

# Set ZSH as default shell
echo "[INFO] Setting ZSH as default shell..."
chsh -s /usr/bin/zsh

# Clean up
echo "[INFO] Cleaning up..."
yay -Rns --noconfirm $(pacman -Qdtq)
yay -Rns --noconfirm ufw-docker 1password-beta 1password-cli spotify pinta obsidian signal-desktop typora xournalpp

# Add configuration files with stow
echo "[INFO] Adding configuration files with stow..."

# First remove default configuration files that might conflict
rm -rf ~/.config/alacritty ~/.config/hypr ~/.config/mpv ~/.config/waybar/config.jsonc ~/.config/wireplumber ~/.zsh ~/.zshrc
rm -f ~/.config/spotify-launcher.conf ~/.config/brave-flags.conf

# Go into stow directory
cd ./stow

# Common modules
stow -t ~ alacritty
stow -t ~ brave-flags.conf
stow -t ~ mpv
stow -t ~ spotify-launcher.conf
stow -t ~ waybar
stow -t ~ wireplumber
stow -t ~ .zsh
stow -t ~ .zshrc

# Desktop or laptop specific
if [[ "$device" = "desktop" || "$device" = "vm" ]]; then
  stow -t ~ hypr-desktop
elif [ "$device" = "laptop" ]; then
  stow -t ~ hypr-laptop
fi

cd ..

echo "[INFO] Done!"
echo "[INFO] Please, reboot your system."
