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

# Set timezone
echo "[INFO] Setting timezone..."
sudo timedatectl set-timezone Europe/Madrid
sudo timedatectl set-local-rtc 0

# Update and upgrade packages
echo "[INFO] Updating and upgrading packages..."
sudo pacman -Syu --noconfirm

# Install basic packages for installation
echo "[INFO] Installing basic packages for installation..."
sudo pacman -S --noconfirm --needed base-devel git wget curl paru

# Change makeflags from makepkg.conf
echo "[INFO] Changing makeflags from makepkg.conf..."
sudo cp ./replace/etc/makepkg.conf /etc/makepkg.conf

# Install all packages
echo "[INFO] Installing all packages..."
paru -S --noconfirm --needed - < packages.txt

# Install NVIDIA drivers if on desktop
if [ "$device" = "desktop" ]; then
    echo "[INFO] Installing NVIDIA drivers..."
    paru -S --noconfirm --needed - < nvidia_packages.txt
fi

# Install auto-cpufreq if on laptop
if [ "$device" = "laptop" ]; then
    echo "[INFO] Installing auto-cpufreq..."
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && sudo ./auto-cpufreq-installer && cd .. && rm -rf auto-cpufreq
fi

# Set user groups
echo "[INFO] Setting user groups..."
sudo usermod -aG video,audio,lp,scanner,vboxusers,docker $USER

# Enable ly as display manager
echo "[INFO] Enabling ly as display manager..."
sudo systemctl enable ly

# Enable CUPS
echo "[INFO] Enabling CUPS..."
sudo systemctl enable cups

# Enable bluetooth
echo "[INFO] Enabling bluetooth..."
sudo systemctl enable bluetooth

# Set up xorg devices configuration
echo "[INFO] Setting up common xorg devices configuration..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo cp ./replace/etc/X11/xorg.conf.d/00-keyboard.conf /etc/X11/xorg.conf.d/00-keyboard.conf
sudo cp ./replace/etc/X11/xorg.conf.d/00-mouse.conf /etc/X11/xorg.conf.d/00-mouse.conf
if [ "$device" = "desktop" ]; then
    sudo cp ./replace/etc/X11/xorg.conf.d/00-monitor.conf /etc/X11/xorg.conf.d/00-monitor.conf
    sudo cp ./replace/etc/X11/xorg.conf.d/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf
elif [ "$device" = "laptop" ]; then
    sudo cp ./replace/etc/X11/xorg.conf.d/00-touchpad.conf /etc/X11/xorg.conf.d/00-touchpad.conf
    sudo cp ./replace/etc/X11/xorg.conf.d/20-amdgpu.conf /etc/X11/xorg.conf.d/20-amdgpu.conf
fi

# Add environment variables to /etc/environment
echo "[INFO] Adding environment variables to /etc/environment..."
if [[ "$device" = "desktop" || "$device" = "vm" ]]; then
    sudo cp ./replace/etc/environment-desktop /etc/environment
elif [ "$device" = "laptop" ]; then
    sudo cp ./replace/etc/environment-laptop /etc/environment
fi

# Add PAM config for automatically unlocking keyring
echo "[INFO] Adding PAM config for automatically unlocking keyring..."
sudo cp ./replace/etc/pam.d/login /etc/pam.d/login

# Create directories
echo "[INFO] Creating directories..."
mkdir -p {~/Documents,~/Downloads,~/Pictures,~/Videos,~/Music,~/Projects}

# Configure Grub with snapshots
echo "[INFO] Configuring Grub with snapshots..."
if [ "$device" = "desktop" ]; then
    sudo cp ./replace/etc/default/grub-desktop /etc/default/grub
elif [ "$device" = "laptop" ]; then
    sudo cp ./replace/etc/default/grub-laptop /etc/default/grub
elif [ "$device" = "vm" ]; then
    sudo cp ./replace/etc/default/grub-vm /etc/default/grub
fi
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
sudo ufw allow out 53 # DNS

# Configure docker
echo "[INFO] Configuring docker..."
sudo systemctl enable docker.socket

# Set up Papirus folders
echo "[INFO] Setting up Papirus folders..."
papirus-folders -C cat-mocha-mauve --theme Papirus-Dark

# Set up ZSH, Oh My ZSH, Powerlevel10k and ZSH plugins
echo "[INFO] Setting up ZSH, Oh My ZSH, Powerlevel10k and ZSH plugins..."
echo "[INFO] Please, exit ZSH when the installation is finished."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Clean up
echo "[INFO] Cleaning up..."
sudo pacman -Rns --noconfirm yay xterm
rm -rf ~/.cache/yay
rm -rf ~/.config/yay
sudo pacman -Rns --noconfirm $(pacman -Qdtq)

# Add configuration files with stow
echo "[INFO] Adding configuration files with stow..."
# First remove default configuration files
rm -rf ~/.gitconfig ~/.gtkrc-2.0 ~/.icons ~/.ideavimrc ~/.oh-my-zsh ~/.p10k.zsh ~/.themes ~/.Xresources ~/.zshrc
rm -rf ~/.config/alacritty ~/.config/awesome ~/.config/gtk-3.0 ~/.config/Kvantum ~/.config/mpv ~/.config/nvim ~/.config/qt5ct ~/.config/qt6ct ~/.config/rofi ~/.config/xfce4
# Add common modules
cd stow
stow -t ~ .gitconfig
stow -t ~ .icons
stow -t ~ .ideavimrc
stow -t ~ .oh-my-zsh
stow -t ~ .p10k.zsh
stow -t ~ .themes
stow -t ~ .zshrc
stow -t ~ Kvantum
stow -t ~ mimeapps.list
stow -t ~ mpv
stow -t ~ nvim
stow -t ~ qt5ct
stow -t ~ qt6ct
# Add desktop modules
if [[ "$device" = "desktop" || "$device" = "vm" ]]; then
    stow -t ~ .gtkrc-2.0-desktop
    stow -t ~ .Xresources-desktop
    stow -t ~ alacritty-desktop
    stow -t ~ awesome-desktop
    stow -t ~ gtk-3.0-desktop
    stow -t ~ rofi-desktop
    stow -t ~ xfce4-desktop
# Add laptop modules
elif [ "$device" = "laptop" ]; then
    stow -t ~ .gtkrc-2.0-laptop
    stow -t ~ .Xresources-laptop
    stow -t ~ alacritty-laptop
    stow -t ~ awesome-laptop
    stow -t ~ gtk-3.0-laptop
    stow -t ~ rofi-laptop
    stow -t ~ xfce4-laptop
fi
cd ..

echo "[INFO] Done!"
echo "[INFO] Please, reboot your system."