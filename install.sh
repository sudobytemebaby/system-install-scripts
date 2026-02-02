#!/bin/bash

# Скрипт автоматической установки Arch Linux
# Схема: GPT + Btrfs (Subvolumes) + GNOME
# ВНИМАНИЕ: Все данные на выбранном диске будут удалены!

set -e

# --- 1. ПЕРЕМЕННЫЕ ---
DISK="/dev/nvme0n1"           # Диск (проверь через lsblk)
HOSTNAME="archlinux"          # Имя компьютера
USERNAME="user"               # Логин
TIMEZONE="Asia/Barnaul"       # Часовой пояс

echo "--- Инициализация установки на $DISK ---"

# Определяем названия разделов (для NVMe это p1, для SATA это 1)
if [[ $DISK == *"nvme"* ]]; then
    PART_BOOT="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_BOOT="${DISK}1"
    PART_ROOT="${DISK}2"
fi

# --- 2. РАЗМЕТКА ДИСКА (GPT) ---
echo "--- Разметка диска ---"
sgdisk -Z $DISK # Очистка таблиц
sgdisk -n 1:0:+512M -t 1:ef00 $DISK # EFI раздел
sgdisk -n 2:0:0     -t 2:8300 $DISK # Root раздел (Btrfs)

# --- 3. СОЗДАНИЕ ФАЙЛОВЫХ СИСТЕМ ---
echo "--- Форматирование разделов ---"
mkfs.fat -F32 $PART_BOOT
mkfs.btrfs -L Archlinux -f $PART_ROOT

# --- 4. СОЗДАНИЕ SUBVOLUMES (Btrfs) ---
echo "--- Настройка Btrfs Subvolumes ---"
mount $PART_ROOT /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots
umount /mnt

# --- 5. МОНТИРОВАНИЕ ---
echo "--- Монтирование системы ---"
MOUNT_OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

mount -o $MOUNT_OPTS,subvol=@ $PART_ROOT /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,tmp,.snapshots,boot}

mount -o $MOUNT_OPTS,subvol=@home $PART_ROOT /mnt/home
mount -o $MOUNT_OPTS,subvol=@log $PART_ROOT /mnt/var/log
mount -o $MOUNT_OPTS,subvol=@pkg $PART_ROOT /mnt/var/cache/pacman/pkg
mount -o $MOUNT_OPTS,subvol=@tmp $PART_ROOT /mnt/tmp
mount -o $MOUNT_OPTS,subvol=@snapshots $PART_ROOT /mnt/.snapshots
mount $PART_BOOT /mnt/boot

# --- 6. УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ---
echo "--- Установка системы (pacstrap) ---"
pacstrap /mnt base base-devel linux linux-firmware linux-headers \
    btrfs-progs snapper grub-btrfs amd-ucode networkmanager \
    grub efibootmgr os-prober git gnome gnome-tweaks gdm \
    mesa vulkan-radeon libva-mesa-driver flatpak

# --- 7. ГЕНЕРАЦИЯ FSTAB ---
genfstab -U /mnt >> /mnt/etc/fstab

# --- 8. НАСТРОЙКА ВНУТРИ CHROOT ---
echo "--- Настройка внутри системы ---"
arch-chroot /mnt /bin/bash <<EOF
    # Время и локали
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    
    # Сеть
    echo "$HOSTNAME" > /etc/hostname
    echo "127.0.0.1 localhost" >> /etc/hosts
    echo "::1       localhost" >> /etc/hosts
    echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
    
    # Пользователь (пароль по умолчанию '1234')
    useradd -m -G wheel,video,audio,storage $USERNAME
    echo "$USERNAME:1234" | chpasswd
    echo "root:1234" | chpasswd
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    
    # Загрузчик (без шифрования - просто ставим)
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    
    # Сервисы
    systemctl enable NetworkManager
    systemctl enable gdm
    
    # Очистка /tmp (как в твоем гайде)
    echo "D! /tmp 1777 root root 0" > /etc/tmpfiles.d/tmp.conf
EOF

# --- 9. ЗАВЕРШЕНИЕ ---
echo "--- Установка завершена! Перезагрузитесь. ---"
umount -R /mnt
