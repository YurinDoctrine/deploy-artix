#!/bin/bash -e

if [ "$(id -u)" -ne 0 ]; then
  echo -e "This script must be run as root. Use 'sudo' or run it as root."
  exit 1
fi

confirm_password() {
  stty -echo
  until [ "$pass1" = "$pass2" ] && [ "$pass2" ]; do
    printf "\n%s\n" "$1" >&2 && read -p $"> " pass1
    printf "\nRe-type %s\n" "$1" >&2 && read -p $"> " pass2
  done
  stty echo
  echo -e "$pass2"
}

# Dependencies
pacman -Sy --noconfirm parted
clear

# Load keymap
echo -e "Load keymap (e.g. us): " && read -p $"> " MY_KEYMAP && loadkeys $MY_KEYMAP
[ ! "$MY_KEYMAP" ] && MY_KEYMAP="us"

# Check boot mode
[ ! -d /sys/firmware/efi ] && echo -e "Not booted in UEFI mode." && exit 1

# Check MY_INIT
case "$(readlink -f /sbin/init)" in
*"openrc"*)
  MY_INIT="openrc"
  echo -e "Init system ("$MY_INIT"): "
  ;;
*"runit"*)
  MY_INIT="runit"
  echo -e "Init system ("$MY_INIT"): "
  ;;
esac

# Choose disk
while :; do
  echo ""
  sfdisk -l
  echo -e "WARNING: The selected disk will be rewritten."
  echo -e "Disk to install to (e.g. /dev/Xda): " && read -p $"> " MY_DISK
  [ -b "$MY_DISK" ] && break
done

PART1="$MY_DISK"1
PART2="$MY_DISK"2
case "$MY_DISK" in
*"nvme"*)
  PART1="$MY_DISK"p1
  PART2="$MY_DISK"p2
  ;;
esac

ROOT_PART=$PART2

# Choose filesystem
until [ ! -e $MY_FS ]; do
  echo -e "Filesystem (btrfs/Default: ext4): " && read -p $"> " MY_FS
  [ ! "$MY_FS" ] && MY_FS="ext4"
done

# Encrypt
until [ ! -e $ENCRYPTED ]; do
  echo -e "Encrypt filesystem? (y/N): " && read -p $"> " ENCRYPTED
  [ ! "$ENCRYPTED" ] && ENCRYPTED="n"
done

if [ "$ENCRYPTED" = "y" ]; then
  CRYPTPASS=$(confirm_password "Password for encryption: ")
fi

# Timezone
until [ -f /usr/share/zoneinfo/"$REGION_CITY" ]; do
  echo -e "Region/City (e.g. America/Denver): " && read -p $"> " REGION_CITY
  [ ! "$REGION_CITY" ] && REGION_CITY="America/Denver"
done

# Host
while :; do
  echo -e "Hostname: " && read -p $"> " MY_HOSTNAME
  [ "$MY_HOSTNAME" ] && break
done

# Username
while :; do
  echo -e "Username: " && read -p $"> " MY_USERNAME
  [ "$MY_USERNAME" ] && break
done

# Root
ROOT_PASSWORD=$(confirm_password "Password for superuser (will use same for root): ")

# Partition disk
parted -s "$MY_DISK" mklabel gpt
parted -s "$MY_DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$MY_DISK" mkpart primary "$MY_FS" 512MiB 100%
parted -s "$MY_DISK" set 1 boot on

if [ "$ENCRYPTED" = "y" ]; then
  yes "$CRYPTPASS" | cryptsetup -q luksFormat "$ROOT_PART"
  yes "$CRYPTPASS" | cryptsetup open "$ROOT_PART" root

  ROOT_PART="/dev/mapper/root"
fi

# Format and mount partitions
mkfs.fat -F 32 "$PART1"
fatlabel "$PART1" ESP

if [ "$MY_FS" = "ext4" ]; then
  mkfs.ext4 "$ROOT_PART"

  mount "$ROOT_PART" /mnt
elif [ "$MY_FS" = "btrfs" ]; then
  mkfs.btrfs "$ROOT_PART"

  mount "$ROOT_PART" /mnt
fi

mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi

echo -e 'Done with configuration. Installing...'

# Install base system and kernel
case $(grep vendor /proc/cpuinfo) in
*"Intel"*)
  ucode="intel-ucode"
  ;;
*"Amd"*)
  ucode="amd-ucode"
  ;;
esac

if [ "$MY_FS" = "btrfs" ]; then
  if [ "$ENCRYPTED" = "y" ]; then
    basestrap /mnt base base-devel $MY_INIT elogind-$MY_INIT efibootmgr grub $ucode dhcpcd wpa_supplicant connman-$MY_INIT btrfs-progs cryptsetup cryptsetup-$MY_INIT
  else
    basestrap /mnt base base-devel $MY_INIT elogind-$MY_INIT efibootmgr grub $ucode dhcpcd wpa_supplicant connman-$MY_INIT btrfs-progs
  fi
else
  if [ "$ENCRYPTED" = "y" ]; then
    basestrap /mnt base base-devel $MY_INIT elogind-$MY_INIT efibootmgr grub $ucode dhcpcd wpa_supplicant connman-$MY_INIT cryptsetup cryptsetup-$MY_INIT
  else
    basestrap /mnt base base-devel $MY_INIT elogind-$MY_INIT efibootmgr grub $ucode dhcpcd wpa_supplicant connman-$MY_INIT
  fi
fi
basestrap /mnt linux linux-headers linux-firmware mkinitcpio
fstabgen -U /mnt >/mnt/etc/fstab

# Chroot
(MY_INIT="$MY_INIT" MY_FS="$MY_FS" ROOT_PART="$ROOT_PART" ROOT_PASSWORD="$ROOT_PASSWORD" ENCRYPTED="$ENCRYPTED" REGION_CITY="$REGION_CITY" MY_HOSTNAME="$MY_HOSTNAME" MY_USERNAME="$MY_USERNAME" MY_KEYMAP="$MY_KEYMAP" artix-chroot /mnt /bin/bash -c 'bash <(curl -s https://raw.githubusercontent.com/YurinDoctrine/deploy-artix/main/deploy.sh); exit') &&
  echo -e 'You may now reboot or poweroff...'
