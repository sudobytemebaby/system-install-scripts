#!/bin/bash

# =============================================================================
# ARCH LINUX FINAL SETUP SCRIPT
# =============================================================================
# This script configures Snapper, Kanata, Firewall, and Dotfiles.

set -e

echo "=== Starting Final Configuration ==="

# --- 1. КАНАТА (Клавиатурный ремаппер) ---
echo "Configuring Kanata..."
sudo groupadd -r uinput || true
sudo usermod -aG input,uinput $USER

# Создаем udev правила для uinput
sudo tee /etc/udev/rules.d/99-uinput.rules << 'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

# Загружаем модуль uinput при загрузке
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput

# --- 2. SNAPPER (Настройка снимков по твоему гайду) ---
echo "Configuring Snapper..."
sudo umount /.snapshots || true
sudo rm -rf /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount /.snapshots
sudo snapper -c root create --description "Post-install base"

# Настройка лимитов (12 часовых, 7 дневных, и т.д.)
sudo sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="12"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="4"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="3"/' /etc/snapper/configs/root

# Включаем таймеры Snapper и grub-btrfs
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo systemctl enable --now grub-btrfsd.service

# --- 3. FIREWALL (UFW) ---
echo "Configuring Firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable --now ufw

# --- 5. ФИНАЛЬНЫЕ ПРАВА И СЕРВИСЫ ---
sudo systemctl daemon-reload

echo "=== All Done! System is ready for work. ==="
