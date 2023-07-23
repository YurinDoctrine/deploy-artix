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

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Root user
yes "$ROOT_PASSWORD" | passwd

sed -i -e '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers

# Other stuff you should do
if [ "$MY_INIT"="openrc" ]; then
  rc-update add connmand default
elif [ "$MY_INIT"="runit" ]; then
  ln -s /etc/runit/sv/connmand/ /etc/runit/runsvdir/current
fi

# Configure mkinitcpio
if [ "$MY_FS"="btrfs" ]; then
  sed -i -e 's/BINARIES=()/BINARIES=(\/usr\/bin\/btrfs)/g' /etc/mkinitcpio.conf
fi
sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block filesystems fsck)/g' /etc/mkinitcpio.conf

mkinitcpio -P
