#!/bin/bash

confirm_password() {
  stty -echo
  until [ "$pass1" = "$pass2" ] && [ "$pass2" ]; do
    echo -e "%s: " "$1" >&2 && read -p pass1
    echo -e "Confirm %s: " "$1" >&2 && read -p pass2
  done
  stty echo
  echo -e "$pass2"
}

# Load keymap
echo -e "Load keymap (e.g. us): " && read -p $MY_KEYMAP && sudo loadkeys $MY_KEYMAP
[ ! "$MY_KEYMAP" ] && MY_KEYMAP = "us"

# Check boot mode
[ ! -d /sys/firmware/efi ] && echo -e "WARNING: Not booted in UEFI mode."

# Check MY_INIT
case "$(readlink -f /sbin/init)" in
*openrc*)
  MY_INIT = "openrc"
  echo -e "Init system ("$MY_INIT"): "
  ;;
*runit*)
  MY_INIT = "runit"
  echo -e "Init system ("$MY_INIT"): "
  ;;

# Choose disk
while :; do
  echo ""
  sudo fdisk -l
  echo -e "WARNING: the selected disk will be rewritten."
  echo -e "Disk to install to (e.g. /dev/Xda): " && read -p MY_DISK
  [ -b "$MY_DISK" ] && break
done


PART1 = "$MY_DISK"1
PART2 = "$MY_DISK"2
PART3 = "$MY_DISK"3
case "$MY_DISK" in
*"nvme"*)
  PART1 = "$MY_DISK"p1
  PART2 = "$MY_DISK"p2
  PART3 = "$MY_DISK"p3
  ;;
esac

# Swap size
until (echo "$SWAP_SIZE" | grep -Eq "^[0-9]+$") && [ "$SWAP_SIZE" -gt 0 ] && [ "$SWAP_SIZE" -lt 97 ]; do
  echo -e "Size of swap partition in GiB (Default: 4GB): " && read -p SWAP_SIZE
  [ ! "$SWAP_SIZE" ] && SWAP_SIZE = 4
done

# Choose filesystem
until [ "$MY_FS" = "btrfs" ] || [ "$MY_FS" = "ext4" ]; do
  echo -e "Filesystem (btrfs/ext4): " && read -p MY_FS
  [ ! "$MY_FS" ] && MY_FS = "btrfs"
done

ROOT_PART = $PART3
[ "$MY_FS" = "ext4" ] && ROOT_PART = $PART2

# Encrypt
echo -e "Encrypt? (y/N): " && read -p ENCRYPTED
[ ! "$ENCRYPTED" ] && ENCRYPTED = "n"

# Layout
MY_ROOT="/dev/mapper/root"
MY_SWAP="/dev/mapper/swap"
if [ "$ENCRYPTED" = "y" ]; then
  CRYPTPASS=$(confirm_password "Encryption Password: ")
else
  MY_ROOT = $PART3
  MY_SWAP = $PART2
  [ "$MY_FS" = "ext4" ] && MY_ROOT = $PART2
fi
[ "$MY_FS" = "ext4" ] && MY_SWAP = "/dev/MyVolGrp/swap"

# Timezone
until [ -f /usr/share/zoneinfo/"$REGION_CITY" ]; do
  printf "Region/City (e.g. 'America/Denver'): " && read -p REGION_CITY
  [ ! "$REGION_CITY" ] && REGION_CITY = "America/Denver"
done

# Host
while :; do
  printf "Hostname: " && read -p MY_HOSTNAME
  [ "$MY_HOSTNAME" ] && break
done

# Users
ROOT_PASSWORD=$(confirm_password "Root Password: ")

installvars() {
  echo -e MY_INIT="$MY_INIT" MY_DISK="$MY_DISK" PART1="$PART1" PART2="$PART2" PART3="$PART3" \
    SWAP_SIZE="$SWAP_SIZE" MY_FS="$MY_FS" ROOT_PART="$ROOT_PART" ENCRYPTED="$ENCRYPTED" MY_ROOT="$MY_ROOT" MY_SWAP="$MY_SWAP" \
    REGION_CITY="$REGION_CITY" MY_HOSTNAME="$MY_HOSTNAME" \
    CRYPTPASS="$CRYPTPASS" ROOT_PASSWORD="$ROOT_PASSWORD"
}

echo -e "Done with configuration. Installing..."

# Partition disk
if [ "$MY_FS" = "ext4" ]; then
  layout = ",,V"
  fs_pkgs = "lvm2 lvm2-$MY_INIT"
elif [ "$MY_FS" = "btrfs" ]; then
  layout = ",${SWAP_SIZE}G,S\n,,"
  fs_pkgs = "btrfs-progs"
fi
[ "$ENCRYPTED" = "y" ] && fs_pkgs = $fs_pkgs + " cryptsetup cryptsetup-$MY_INIT"

printf "label: gpt\n,550M,U\n%s\n" "$layout" | sudo sfdisk "$MY_DISK"

# Format and mount partitions
if [ "$ENCRYPTED" = "y" ]; then
  yes "$CRYPTPASS" | sudo cryptsetup -q luksFormat "$ROOT_PART"
  yes "$CRYPTPASS" | sudo cryptsetup open "$ROOT_PART" root

  if [ "$MY_FS" = "btrfs" ]; then
    yes "$CRYPTPASS" | sudo cryptsetup -q luksFormat "$PART2"
    yes "$CRYPTPASS" | sudo cryptsetup open "$PART2" swap
  fi
fi

sudo mkfs.fat -F 32 "$PART1"

if [ "$MY_FS" = "ext4" ]; then
# Setup LVM
  sudo pvcreate "$MY_ROOT"
  sudo vgcreate MyVolGrp "$MY_ROOT"
  sudo lvcreate -L "$SWAP_SIZE"G MyVolGrp -n swap
  sudo lvcreate -l 100%FREE MyVolGrp -n root

  sudo mkfs.ext4 /dev/MyVolGrp/root

  sudo mount /dev/MyVolGrp/root /mnt
elif [ "$MY_FS" = "btrfs" ]; then
  sudo mkfs.btrfs "$MY_ROOT"

  # Create subvolumes
  sudo mount "$MY_ROOT" /mnt
  sudo btrfs subvolume create /mnt/root
  sudo btrfs subvolume create /mnt/home
  sudo umount -R /mnt

  # Mount subvolumes
  sudo mount -t btrfs -o compress=zstd,subvol=root "$MY_ROOT" /mnt
  sudo mkdir /mnt/home
  sudo mount -t btrfs -o compress=zstd,subvol=home "$MY_ROOT" /mnt/home
fi

sudo mkswap "$MY_SWAP"
sudo mkdir /mnt/boot
sudo mount "$PART1" /mnt/boot

case $(grep vendor /proc/cpuinfo) in
*"Intel"*)
  ucode="intel-ucode"
  ;;
*"Amd"*)
  ucode="amd-ucode"
  ;;
esac

# Install base system and kernel
sudo basestrap /mnt base base-devel "$MY_INIT" elogind-"$MY_INIT" "$fs_pkgs" efibootmgr grub "$ucode" dhcpcd wpa_supplicant connman-"$MY_INIT" &&
sudo basestrap /mnt linux linux-firmware linux-headers mkinitcpio &&
sudo fstabgen -U /mnt >/mnt/etc/fstab

# Chroot
sudo cp src/deploy.sh /mnt/root/ &&
  sudo "$(installvars)" deploy-artix /mnt /bin/bash -c 'sh /root/deploy.sh; rm /root/deploy.sh; exit' &&
  echo -e 'You may now poweroff...'
