#!/bin/bash -e

# Boring stuff you should probably do
ln -sf /usr/share/zoneinfo/"$REGION_CITY" /etc/localtime
hwclock --systohc

# Localization
echo -e "en_GB.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo -e "LANG=en_GB.UTF-8" >/etc/locale.conf
echo -e "KEYMAP=$MY_KEYMAP" >/etc/vconsole.conf

# Host stuff
echo -e "$MY_HOSTNAME" >/etc/hostname
echo -e 'hostname="$MY_HOSTNAME"' >/etc/conf.d/hostname
printf "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t%s.localdomain\t%s\n" "$MY_HOSTNAME" "$MY_HOSTNAME" >/etc/hosts

# Install boot loader
ROOT_PART_uuid=$(blkid "$ROOT_PART" -o value -s UUID)

sed -i -e "s/^GRUB_CMDLINE_LINUX_DEFAULT.*$/GRUB_CMDLINE_LINUX_DEFAULT=\"$my_params\"/g" /etc/default/grub
[ "$ENCRYPTED"="y" ] && sed -i -e '/GRUB_ENABLE_CRYPTODISK=y/s/^#//g' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot --recheck
grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Root user
yes "$ROOT_PASSWORD" | passwd

sed -i -e '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers

# Other stuff you should do
if [ "$MY_INIT"="openrc" ]; then
  rc-update add connmand default
elif [ "$MY_INIT"="runit" ]; then
  ln -s /etc/runit/sv/connmand /run/runit/service
fi

[ "$MY_FS"="ext4" ] && [ "$MY_INIT"="openrc" ] && rc-update add lvm boot

printf "\n%s\t\tswap\t\tswap\t\tsw\t0 0\n" "$MY_SWAP" >>/etc/fstab

if [ "$ENCRYPTED"="y" ] && [ "$MY_FS"="btrfs" ]; then
  swap_uuid=$(blkid "$PART2" -o value -s UUID)

  mkdir /root/.keyfiles
  chmod 0400 /root/.keyfiles
  dd if=/dev/urandom of=/root/.keyfiles/main bs=1024 count=4
  yes "$CRYPTPASS" | cryptsetup luksAddKey "$PART2" /root/.keyfiles/main
  printf "dmcrypt_key_timeout=1\ndmcrypt_retries=5\n\ntarget='swap'\nsource=UUID='%s'\nkey='/root/.keyfiles/main'\n#\n" "$swap_uuid" >/etc/conf.d/dmcrypt

  [ "$MY_INIT"="openrc" ] && rc-update add dmcrypt boot
fi

# Configure mkinitcpio
if [ "$MY_FS"="ext4" ]; then
  if [ "$ENCRYPTED"="y" ]; then
    sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)/g' /etc/mkinitcpio.conf
  else
    sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block lvm2 filesystems fsck)/g' /etc/mkinitcpio.conf
  fi
elif [ "$MY_FS"="btrfs" ]; then
  sed -i -e 's/BINARIES=()/BINARIES=(\/usr\/bin\/btrfs)/g' /etc/mkinitcpio.conf
  if [ "$ENCRYPTED"="y" ]; then
    sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/g' /etc/mkinitcpio.conf
  else
    sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block filesystems fsck)/g' /etc/mkinitcpio.conf
  fi
fi

mkinitcpio -P
