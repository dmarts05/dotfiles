#!/bin/bash

# Check if user is root
if [ "$EUID" -eq 0 ]; then
    echo "[ERROR] Please do not run this script as root, exiting..."
    exit
fi

# Set timezone
echo "[INFO] Setting timezone..."
sudo timedatectl set-timezone Europe/Madrid
sudo timedatectl set-local-rtc 0

# Update and upgrade packages
echo "[INFO] Updating and upgrading packages..."
sudo pacman -Syu --noconfirm

# Install some needed packages
echo "[INFO] Installing some needed packages..."
sudo pacman -S --noconfirm --needed base-devel git wget curl

# Install EOS packages from eos_packages.txt (just in case you missed a package while installing EOS)
echo "[INFO] Installing packages from eos_packages.txt..."
sudo pacman -S --noconfirm --needed - < eos_packages.txt

# Install paru
echo "[INFO] Installing paru..."
sudo pacman -S --noconfirm --needed paru

# Change makeflags from makepkg.conf
echo "[INFO] Changing makeflags from makepkg.conf..."
sudo cp ./etc/makepkg.conf /etc/makepkg.conf

# Install user packages from user_packages.txt (AUR packages included)
echo "[INFO] Installing packages from user_packages.txt..."
paru -S --noconfirm --needed - < user_packages.txt

# Enable lightdm
echo "[INFO] Enabling lightdm..."
sudo systemctl enable lightdm

# Add lightdm extra configuration
echo "[INFO] Adding lightdm extra configuration..."
sudo cp ./etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/

# Enable CUPS
echo "[INFO] Enabling CUPS..."
sudo systemctl enable cups

# Enable bluetooth
echo "[INFO] Enabling bluetooth..."
sudo systemctl enable bluetooth

# Set up xorg devices configuration
echo "[INFO] Setting up xorg devices configuration..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo cp ./etc/X11/xorg.conf.d/* /etc/X11/xorg.conf.d/

# Add environment variables to /etc/environment
echo "[INFO] Adding environment variables to /etc/environment..."
sudo cp ./etc/environment /etc/environment

# Add PAM config for automatically unlocking keyring
echo "[INFO] Adding PAM config for automatically unlocking keyring..."
sudo cp ./etc/pam.d/login /etc/pam.d/login

# Add fonts and images
echo "[INFO] Adding fonts and images..."
sudo mkdir -p /usr/share/fonts /usr/share/icons /usr/share/themes /usr/share/images
sudo cp -r ./usr/share/fonts/* /usr/share/fonts/
sudo cp -r ./usr/share/images/* /usr/share/images/

# Create directories
echo "[INFO] Creating directories..."
mkdir -p {~/Documents,~/Downloads,~/Pictures,~/Videos,~/Music,~/Projects}

# Set up snapshots with Timeshift and configure GRUB
echo "[INFO] Setting up snapshots with Timeshift and configuring GRUB..."
sudo cp ./etc/default/grub /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable --now cronie
sudo systemctl enable --now grub-btrfsd

# Set up git
echo "[INFO] Setting up git..."
git config --global user.name "dmarts05"
git config --global user.email "dmarts05@estudiantes.unileon.es"

# Set up UFW firewall
echo "[INFO] Setting up UFW firewall..."
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow qBittorrent

# Set up VirtualBox
echo "[INFO] Setting up VirtualBox..."
sudo usermod -aG vboxusers $USER

# Set up Papirus folders
echo "[INFO] Setting up Papirus folders..."
papirus-folders -C cat-mocha-mauve --theme Papirus-Dark

# Set up Poetry
echo "[INFO] Setting up Poetry..."
poetry config virtualenvs.in-project true
poetry config virtualenvs.prefer-active-python true

# Set up ZSH, Oh My ZSH, Powerlevel10k and ZSH plugins
echo "[INFO] Setting up ZSH, Oh My ZSH, Powerlevel10k and ZSH plugins..."
echo "[INFO] Please, exit ZSH when the installation is finished."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/catppuccin/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting-catppuccin
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
cp .zshrc ~/.zshrc
cp .p10k.zsh ~/.p10k.zsh

# Set up LunarVim
echo "[INFO] Setting up LunarVim..."
LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh)
rm -rf ~/.config/lvim
git clone https://github.com/dmarts05/lvim.git ~/.config/lvim

# Set common groups for the user
echo "[INFO] Setting common groups for the user..."
sudo usermod -aG video,audio,lp,scanner $USER

# Perform nvdia-install to install remaining NVIDIA packages
echo "[INFO] Installing NVIDIA packages..."
nvidia-inst

# Clean up
echo "[INFO] Cleaning up..."
sudo pacman -Rns --noconfirm yay xterm
rm -rf ~/.cache/yay
rm -rf ~/.config/yay
sudo pacman -Rns --noconfirm $(pacman -Qdtq)

# Set up .config files
echo "[INFO] Setting up .config files..."
mkdir -p ~/.config
cp -r ./.config/* ~/.config
cp -r ./.icons ~/.icons
sudo cp -r ./.icons /root/.icons
cp .gtkrc-2.0 ~/.gtkrc-2.0
sudo cp .gtkrc-2.0 /root/.gtkrc-2.0
sudo mkdir -p /root/.config
sudo cp -r ./.config/Kvantum /root/.config
sudo cp -r ./.config/gtk-3.0 /root/.config
cp .Xresources ~/.Xresources
cp .xprofile ~/.xprofile

echo "[INFO] Done!"
echo "[INFO] Please, reboot your system."