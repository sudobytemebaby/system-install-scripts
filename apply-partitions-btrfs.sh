#!/bin/bash

# =============================================================================
# ARCH LINUX DISK PARTITIONING & BTRFS SETUP
# =============================================================================
# This script prepares GPT partitions, creates Btrfs subvolumes, and mounts 
# them to /mnt. WARNING: This will erase all data on the selected drive!

set -e

# --- 1. Identify the disk ---
echo "Listing available drives:"
lsblk -d -n -o NAME,SIZE,MODEL

echo ""
read -p "Enter the disk to partition (e.g., /dev/nvme0n1 or /dev/sda): " DISK

# Confirm before proceeding
read -p "DANGER: All data on $DISK will be destroyed. Are you sure? (y/N): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Aborted."
    exit 1
fi

# Determine partition naming (p1/p2 for NVMe, 1/2 for SATA)
if [[ $DISK == *"nvme"* ]]; then
    PART_BOOT="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_BOOT="${DISK}1"
    PART_ROOT="${DISK}2"
fi

# --- 2. Partitioning (GPT) ---
echo "Partitioning $DISK..."
sgdisk -Z $DISK # Zap existing partition table
sgdisk -n 1:0:+512M -t 1:ef00 $DISK # EFI Partition
sgdisk -n 2:0:0     -t 2:8300 $DISK # Linux Root (Btrfs)

# --- 3. Creating Filesystems ---
echo "Formatting partitions..."
mkfs.fat -F32 $PART_BOOT
mkfs.btrfs -L Archlinux -f $PART_ROOT

# --- 4. Subvolume Creation ---
echo "Creating Btrfs subvolumes..."
mount $PART_ROOT /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots

umount /mnt

# --- 5. Final Mounting ---
echo "Mounting subvolumes with optimized options..."
# Using zstd compression and SSD optimizations as per your guide
MOUNT_OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

# Mount root
mount -o $MOUNT_OPTS,subvol=@ $PART_ROOT /mnt

# Create mount points
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,tmp,.snapshots,boot}

# Mount other subvolumes
mount -o $MOUNT_OPTS,subvol=@home $PART_ROOT /mnt/home
mount -o $MOUNT_OPTS,subvol=@log $PART_ROOT /mnt/var/log
mount -o $MOUNT_OPTS,subvol=@pkg $PART_ROOT /mnt/var/cache/pacman/pkg
mount -o $MOUNT_OPTS,subvol=@tmp $PART_ROOT /mnt/tmp
mount -o $MOUNT_OPTS,subvol=@snapshots $PART_ROOT /mnt/.snapshots

# Mount EFI boot partition
mount $PART_BOOT /mnt/boot

echo "--- Partitioning and mounting complete! ---"
echo "Structure is ready at /mnt. You can now run pacstrap."
lsblk $DISK
