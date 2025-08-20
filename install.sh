#!/bin/bash

# Check if user is root
if [ "$EUID" -eq 0 ]; then
    echo "[ERROR] Please do not run this script as root, exiting..."
    exit
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
sudo pacman -Syu --noconfirm

# Install basic packages for installation
echo "[INFO] Installing basic packages for installation..."
sudo pacman -S --noconfirm --needed base-devel git wget curl

# Install Omarchy
wget -qO- https://omarchy.org/install-bare | bash

# Install app packages
echo "[INFO] Installing app packages..."
paru -S --noconfirm --needed - < packages.txt

# Install NVIDIA drivers if on desktop
if [ "$device" = "desktop" ]; then
    echo "[INFO] Installing NVIDIA drivers..."
    paru -S --noconfirm --needed libva-nvidia-driver nvidia nvidia-settings nvidia-utils nvtop

    echo "[INFO] Configuring mkinitcpio for NVIDIA early KMS..."
    CONF="/etc/mkinitcpio.conf"
    MODULES_TO_ADD=("nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")

    # Backup first
    sudo cp "$CONF" "${CONF}.bak.$(date +%s)"

    # Extract current MODULES= line
    current=$(grep -E '^MODULES=' "$CONF")

    # Remove parentheses and split into array
    current_mods=($(echo "$current" | sed -E 's/^MODULES=\(|\)$//g'))

    # Ensure existing ones are preserved
    new_mods=()
    for mod in "${current_mods[@]}"; do
        [[ " ${new_mods[*]} " == *" $mod "* ]] || new_mods+=("$mod")
    done

    # Add NVIDIA modules if missing
    for mod in "${MODULES_TO_ADD[@]}"; do
        [[ " ${new_mods[*]} " == *" $mod "* ]] || new_mods+=("$mod")
    done

    # Build new MODULES line
    new_line="MODULES=(${new_mods[*]})"

    # Replace in config
    sudo sed -i "s|^MODULES=.*|$new_line|" "$CONF"

    # Rebuild initramfs
    echo "[INFO] Regenerating initramfs..."
    sudo mkinitcpio -P
fi

# Install virtualization guest packages if running inside a VM
if [ "$device" = "vm" ]; then
    echo "[INFO] Installing virtualization guest packages..."
    sudo pacman -S --noconfirm --needed qemu-guest-agent spice-vdagent xf86-video-qxl

    echo "[INFO] Enabling QEMU guest agent..."
    sudo systemctl enable qemu-guest-agent
fi


# Set general user groups
echo "[INFO] Setting general user groups..."
sudo usermod -aG video,audio,lp,scanner $USER

# Create directories
echo "[INFO] Creating directories..."
mkdir -p {~/Documents,~/Downloads,~/Pictures,~/Videos,~/Music,~/Projects}

# Set up cronie service required for Timeshift
sudo systemctl enable cronie

# Set up libvirt services
sudo systemctl enable libvirtd
sudo systemctl enable virtlogd

# Copy files from replace to libvirt config folder
sudo cp -r ./replace/etc/libvirt/* /etc/libvirt/

# Set up nautilus open any terminal extension
sudo glib-compile-schemas /usr/share/glib-2.0/schemas
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal alacritty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal keybindings '<Ctrl><Alt>t'
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal flatpak system

# Set ZSH as default shell
echo "[INFO] Setting ZSH as default shell..."
chsh -s /usr/bin/zsh

# Clean up
echo "[INFO] Cleaning up..."
sudo pacman -Rns --noconfirm $(pacman -Qdtq)

# Add configuration files with stow
echo "[INFO] Adding configuration files with stow..."

# First remove default configuration files that might conflict
rm -rf ~/.config/alacritty ~/.config/hypr ~/.config/mpv ~/.config/wireplumber
rm -f ~/.config/spotify-launcher.conf ~/.config/brave-flags.conf

# Go into stow directory
cd ./stow

# Common modules
stow -t ~ mpv
stow -t ~ wireplumber
stow -t ~ brave-flags.conf
stow -t ~ spotify-launcher.conf

# Desktop or laptop specific
if [[ "$device" = "desktop" || "$device" = "vm" ]]; then
    stow -t ~ alacritty-desktop
    stow -t ~ hypr-desktop
elif [ "$device" = "laptop" ]; then
    stow -t ~ alacritty-laptop
    stow -t ~ hypr-laptop
fi

cd ..

echo "[INFO] Done!"
echo "[INFO] Please, reboot your system."
