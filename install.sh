#!/bin/bash

# Check if user is root
if [ "$EUID" -eq 0 ]; then
    echo "[ERROR] Please do not run this script as root, exiting..."
    exit
fi

# Ask user if they need NVIDIA drivers
echo "[INFO] Do you need NVIDIA drivers? (y/n)"
read -r nvidia

echo "[INFO] Starting installation..."

# Set timezone
echo "[INFO] Setting timezone..."
sudo timedatectl set-timezone Europe/Madrid
sudo timedatectl set-local-rtc 0

# Update and upgrade packages
echo "[INFO] Updating and upgrading packages..."
sudo pacman -Syu --noconfirm

# Install basic packages for installation
echo "[INFO] Installing basic packages for installation..."
sudo pacman -S --noconfirm --needed base-devel git wget curl

# Install paru
echo "[INFO] Installing paru..."
sudo pacman -S --noconfirm --needed paru

# Change makeflags from makepkg.conf
echo "[INFO] Changing makeflags from makepkg.conf..."
sudo cp ./replace/etc/makepkg.conf /etc/makepkg.conf

# Install all packages
echo "[INFO] Installing all packages..."
paru -S --noconfirm --needed - < packages.txt

# Install NVIDIA drivers if needed
if [ "$nvidia" = "y" ]; then
    echo "[INFO] Installing NVIDIA drivers..."
    paru -S --noconfirm --needed - < nvidia_packages.txt
fi

# Set groups for the user
echo "[INFO] Setting groups for the user..."
sudo usermod -aG video,audio,lp,scanner,virtualbox,docker $USER

# Enable ly
echo "[INFO] Enabling ly..."
sudo systemctl enable ly

# Enable CUPS
echo "[INFO] Enabling CUPS..."
sudo systemctl enable cups

# Enable bluetooth
echo "[INFO] Enabling bluetooth..."
sudo systemctl enable bluetooth

# Set up xorg devices configuration
echo "[INFO] Setting up xorg devices configuration..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo cp ./replace/etc/X11/xorg.conf.d/* /etc/X11/xorg.conf.d/

# Add environment variables to /etc/environment
echo "[INFO] Adding environment variables to /etc/environment..."
sudo cp ./replace/etc/environment /etc/environment

# Add PAM config for automatically unlocking keyring
echo "[INFO] Adding PAM config for automatically unlocking keyring..."
sudo cp ./replace/etc/pam.d/login /etc/pam.d/login

# Create directories
echo "[INFO] Creating directories..."
mkdir -p {~/Documents,~/Downloads,~/Pictures,~/Videos,~/Music,~/Projects}

# Set up snapshots with Timeshift and configure GRUB
echo "[INFO] Setting up snapshots with Timeshift and configuring GRUB..."
sudo cp ./replace/etc/default/grub /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable cronie
sudo systemctl enable grub-btrfsd

# Set up UFW firewall
echo "[INFO] Setting up UFW firewall..."
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow qBittorrent

# Configure docker
echo "[INFO] Configuring docker..."
sudo systemctl enable docker.socket
sudo usermod -aG docker $USER

# Set up Papirus folders
echo "[INFO] Setting up Papirus folders..."
papirus-folders -C cat-mocha-mauve --theme Papirus-Dark

# Set up ZSH, Oh My ZSH, Powerlevel10k and ZSH plugins
echo "[INFO] Setting up ZSH, Oh My ZSH, Powerlevel10k and ZSH plugins..."
echo "[INFO] Please, exit ZSH when the installation is finished."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/catppuccin/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting-catppuccin
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Add configuration files with stow
echo "[INFO] Adding configuration files with stow..."
cd stow && stow -t ~ * && cd ..

# Clean up
echo "[INFO] Cleaning up..."
sudo pacman -Rns --noconfirm yay xterm
rm -rf ~/.cache/yay
rm -rf ~/.config/yay
sudo pacman -Rns --noconfirm $(pacman -Qdtq)

echo "[INFO] Done!"
echo "[INFO] Please, reboot your system."