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
echo -e "Load keymap (e.g. us): " && read -p $"> " MY_KEYMAP && loadkeys $MY_KEYMAP
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
  sfdisk -l
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

ROOT_PART=$PART2

# Choose filesystem
until [ ! -e $MY_FS ]; do
  echo -e "Filesystem (btrfs/Default: ext4): " && read -p $"> " MY_FS
  [ ! "$MY_FS" ] && MY_FS="ext4"
done

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
    MY_FS="$MY_FS" ROOT_PART="$ROOT_PART" ROOT_PASSWORD="$ROOT_PASSWORD" \
    REGION_CITY="$REGION_CITY" MY_HOSTNAME="$MY_HOSTNAME"
}

echo -e "Done with configuration. Installing..."

# Partition disk
parted -s "$MY_DISK" mklabel gpt
parted -s "$MY_DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$MY_DISK" mkpart primary "$MY_FS" 512MiB 100%
parted -s "$MY_DISK" set 1 boot on

mkfs.fat -F 32 "$PART1"
fatlabel "$PART1" ESP

if [ "$MY_FS"="ext4" ]; then
  mkfs.ext4 -L ROOT "$ROOT_PART"

  mount "$ROOT_PART" /mnt
elif [ "$MY_FS"="btrfs" ]; then
  mkfs.btrfs -L "$ROOT_PART"

  # Create subvolumes
  mount "$ROOT_PART" /mnt
  btrfs subvolume create /mnt/root
  btrfs subvolume create /mnt/home
  umount -R /mnt

  # Mount subvolumes
  mount -t btrfs -o compress=zstd,subvol=root "$ROOT_PART" /mnt
  mkdir /mnt/home
  mount -t btrfs -o compress=zstd,subvol=home "$ROOT_PART" /mnt/home
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
if [ "$MY_FS"="btrfs" ]; then
  basestrap /mnt base base-devel $MY_INIT elogind-$MY_INIT efibootmgr grub $ucode dhcpcd wpa_supplicant connman-$MY_INIT btrfs-progs
else
  basestrap /mnt base base-devel $MY_INIT elogind-$MY_INIT efibootmgr grub $ucode dhcpcd wpa_supplicant connman-$MY_INIT
fi
basestrap /mnt linux linux-headers linux-firmware mkinitcpio
fstabgen -U /mnt >/mnt/etc/fstab

# Chroot
($(installvars) artix-chroot /mnt /bin/bash -c 'bash <(curl -s https://raw.githubusercontent.com/YurinDoctrine/deploy-artix/main/deploy.sh); exit') &&
  echo -e 'You may now reboot or poweroff...'
