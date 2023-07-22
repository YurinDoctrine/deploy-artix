#!/bin/bash -e

if [ "$(id -u)" -ne 0 ]; then
  echo -e "This script must be run as root. Please use 'sudo' or run it as root."
  exit 1
fi

confirm_password() {
  stty -echo
  until [ "$pass1"="$pass2" ] && [ "$pass2" ]; do
    printf "\n%s: \n" "$1" >&2 && read -p $"> " pass1
    printf "\nConfirm %s: \n" "$1" >&2 && read -p $"> " pass2
  done
  stty echo
  echo -e "$pass2"
}

# Load keymap
[ ! "$MY_KEYMAP" ] && MY_KEYMAP="us"

# Check boot mode
[ ! -d /sys/firmware/efi ] && echo -e "WARNING: Not booted in UEFI mode."

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
  echo -e "WARNING: the selected disk will be rewritten."
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

# Choose filesystem
until [ "$MY_FS"="btrfs" ] || [ "$MY_FS"="ext4" ]; do
  echo -e "Filesystem (btrfs/Default: ext4): " && read -p $"> " MY_FS
  [ ! "$MY_FS" ] && MY_FS="ext4"
done

ROOT_PART=$PART2
[ "$MY_FS"="ext4" ] && ROOT_PART=$PART2

# Encrypt
echo -e "Encrypt? (y/N): " && read -p $"> " ENCRYPTED
[ ! "$ENCRYPTED" ] && ENCRYPTED="n"

# Layout
MY_ROOT="/dev/mapper/root"
if [ "$ENCRYPTED"="y" ]; then
  CRYPTPASS=$(confirm_password "Encryption Password: ")
else
  MY_ROOT=$PART2
  [ "$MY_FS"="ext4" ] && MY_ROOT=$PART2
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

# Users
ROOT_PASSWORD=$(confirm_password "Root Password: ")

installvars() {
  echo -e MY_INIT="$MY_INIT" MY_DISK="$MY_DISK" PART1="$PART1" PART2="$PART2" \
    MY_FS="$MY_FS" ROOT_PART="$ROOT_PART" ENCRYPTED="$ENCRYPTED" MY_ROOT="$MY_ROOT" \
    REGION_CITY="$REGION_CITY" MY_HOSTNAME="$MY_HOSTNAME" \
    CRYPTPASS="$CRYPTPASS" ROOT_PASSWORD="$ROOT_PASSWORD"
}

echo -e "Done with configuration. Installing..."

# Partition disk
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$TARGET_DISK" mkpart primary "$MY_FS" 512MiB 100%
parted -s "$TARGET_DISK" set 1 boot on

if [ "$MY_FS"="btrfs" ]; then
  fs_pkgs="btrfs-progs"
fi
[ "$ENCRYPTED"="y" ] && fs_pkgs=$fs_pkgs+" cryptsetup cryptsetup-$MY_INIT"

# Format and mount partitions
if [ "$ENCRYPTED"="y" ]; then

  if [ "$MY_FS"="btrfs" ]; then
  fi
fi


if [ "$MY_FS"="ext4" ]; then

elif [ "$MY_FS"="btrfs" ]; then

  # Create subvolumes

  # Mount subvolumes
fi


case $(grep vendor /proc/cpuinfo) in
*"Intel"*)
  ucode="intel-ucode"
  ;;
*"Amd"*)
  ucode="amd-ucode"
  ;;
esac

# Install base system and kernel

# Chroot
  echo -e 'You may now poweroff...'
