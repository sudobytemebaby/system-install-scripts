#!/bin/bash

# =============================================================================
# ARCH LINUX SETUP SCRIPT (GNOME + VIRTUALIZATION + DEVELOPMENT)
# =============================================================================

set -e # Exit on any error

echo "=== Starting System Setup ==="

# --- STEP 1: Install AUR Helper (paru) ---
if ! command -v paru &> /dev/null; then
    echo "Installing paru AUR helper..."
    sudo pacman -S --needed --noconfirm base-devel git
    cd /tmp && git clone https://aur.archlinux.org/paru.git && cd paru
    makepkg -si --noconfirm
    cd ~ && rm -rf /tmp/paru
fi

# --- STEP 2: System Update ---
echo "Updating system..."
paru -Syu --noconfirm

# --- STEP 3: Core System & Filesystems ---
# Kernel, drivers, and support for NTFS, FAT32, exFAT, and Network Shares
echo "Installing core system and filesystem support..."
paru -S --needed --noconfirm \
    base base-devel linux linux-headers linux-firmware sudo \
    amd-ucode sof-firmware efibootmgr grub grub-btrfs os-prober \
    btrfs-progs snapper fwupd \
    libva-mesa-driver mesa vulkan-radeon \
    ntfs-3g dosfstools exfatprogs \
    gvfs-mtp gvfs-smb gvfs-nfs gvfs-gphoto2

# --- STEP 4: Desktop Environment (GNOME) ---
# Standard GNOME suite and Pipewire audio stack
echo "Installing GNOME environment..."
paru -S --needed --noconfirm \
    gnome gnome-tweaks gdm \
    xdg-desktop-portal-gnome \
    pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse wireplumber

# --- STEP 5: Virtualization (KVM/QEMU/Libvirt) ---
# Professional virtualization stack for high-performance VMs
echo "Installing virtualization stack..."
paru -S --needed --noconfirm \
    qemu-desktop libvirt virt-manager dnsmasq ebtables iptables-nft

# --- STEP 6: Network & Security Tools ---
# Connectivity, DNS, and Infosec tools
echo "Installing network and security tools..."
paru -S --needed --noconfirm \
    networkmanager ufw arch-audit \
    curl wget openssh xray whois \
    bind doggo mtr \
    nmap tcpdump termshark gobuster ffuf

# --- STEP 7: Development Stack ---
# Backend languages, containers, and modern editors
echo "Installing development tools..."
paru -S --needed --noconfirm \
    git neovim zed make cmake clang \
    go nodejs npm rustup go-task \
    podman podman-compose lazygit

# --- STEP 8: CLI Utilities & Shell ---
# Enhanced terminal environment and modern tools
echo "Installing CLI utilities..."
paru -S --needed --noconfirm \
    fish ghostty kitty starship tmux tmux-sessionizer \
    bat btop eza fzf ripgrep fd tree yazi zoxide \
    stow strace tldr translate-shell yt-dlp imagemagick

# --- STEP 9: Hardware Management & Monitoring ---
# Power management and hardware diagnostics
echo "Installing hardware management tools..."
paru -S --needed --noconfirm \
    auto-cpufreq smartmontools radeontop upower

# --- STEP 10: System Infrastructure & Fonts ---
echo "Installing fonts and infra tools..."
paru -S --needed --noconfirm \
    zram-generator kanata \
    noto-fonts ttf-dejavu ttf-apple-emoji \
    ttf-jetbrains-mono-nerd \

# --- STEP 11: Flatpak & GUI Applications ---
# Isolated applications for better visual consistency (Polish)
echo "Installing GUI apps via Flatpak..."
sudo pacman -S --needed --noconfirm flatpak

echo "If nothing happens - reboot"

flatpak install flathub \
    app.zen_browser.zen \
    org.localsend.localsend_app \
    md.obsidian.Obsidian \
    de.haeckerfelix.Fragments

# --- STEP 12: Services, Groups & Permissions ---
echo "Enabling services and configuring user groups..."
sudo systemctl enable gdm.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable libvirtd.service
sudo systemctl enable auto-cpufreq.service

# Permissions for networking and virtualization without sudo
sudo usermod -aG libvirt,wireshark $USER

echo "=== Setup Complete! Please Reboot ==="
