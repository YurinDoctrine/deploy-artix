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
mkdir -p /etc/conf.d
echo -e 'hostname="$MY_HOSTNAME"' >/etc/conf.d/hostname
printf "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t%s.localdomain\t%s\n" "$MY_HOSTNAME" "$MY_HOSTNAME" >/etc/hosts

# User
useradd -m -G users,wheel,audio,video -s /bin/bash $MY_USERNAME
yes "$ROOT_PASSWORD" | passwd $MY_USERNAME

# Root user
yes "$ROOT_PASSWORD" | passwd

sed -i -e '/%wheel ALL=(ALL:ALL) ALL/s/^# //g' /etc/sudoers

# Pacman
echo -e "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://mirrors.qontinuum.space/artixlinux-universe/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/\$arch
Server = https://artix.sakamoto.pl/universe/\$arch
# TOR
Server = http://rrtovkpcaxl6s2ommj5tigyxamzxaknasd74ecb5t5cdfnkodirjnwyd.onion/artixlinux/\$arch
" | tee -a /etc/pacman.conf

pacman -Sy --noconfirm artix-keyring artix-archlinux-support

echo -e "[extra]
Include = /etc/pacman.d/mirrorlist-arch

#[community]
#Include = /etc/pacman.d/mirrorlist-arch

#[multilib]
#Include = /etc/pacman.d/mirrorlist-arch
" | tee -a /etc/pacman.conf

pacman -Sy && pacman-key --init && pacman-key --populate archlinux

# System
pacman -Sy --noconfirm alsa-utils curl git lxdm-$MY_INIT kitty lz4 mesa openbox openssh pipewire procps psmisc wayland wget wireplumber xdg-utils xdg-user-dirs xorg xterm

# Pull my dotfiles
release=$(curl -s https://www.debian.org/releases/stable/ | grep -oP 'Debian [0-9]+' | cut -d " " -f2 | head -n 1)
cd /tmp
git clone --branch $release https://github.com/CBPP/cbpp-ui-theme.git
rm -rfd /usr/share/themes/CBPP*
rm -rfd cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/CBPP/xf*
cp -rfd cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes
rm -rfd /usr/share/backgrounds
mkdir -p /usr/share/backgrounds
git clone --branch artix https://github.com/YurinDoctrine/.config.git
rm -rfd /home/$MY_USERNAME/.*
rm -rfd /etc/skel/.*
rm -rfd /root/.*
rmdir -p /home/$MY_USERNAME/*
rmdir -p /etc/skel/*
rmdir -p /root/*
mkdir -p /home/$MY_USERNAME/.config
mkdir -p /etc/skel/.config
mkdir -p /root/.config
mkdir -p /home/$MY_USERNAME/.local
mkdir -p /etc/skel/.local
cp -rfd .config/.gmrunrc /home/$MY_USERNAME
cp -rfd .config/.gtkrc-2.0 /home/$MY_USERNAME/.gtkrc-2.0
cp -rfd .config/.fonts.conf /home/$MY_USERNAME
cp -rfd .config/.gtk-bookmarks /home/$MY_USERNAME
cp -rfd .config/.vimrc /home/$MY_USERNAME
cp -rfd .config/.Xresources /home/$MY_USERNAME
cp -rfd .config/.nanorc /home/$MY_USERNAME
cp -rfd .config/.gmrunrc /etc/skel
cp -rfd .config/.gtkrc-2.0 /etc/skel/.gtkrc-2.0
cp -rfd .config/.fonts.conf /etc/skel
cp -rfd .config/.gtk-bookmarks /etc/skel
cp -rfd .config/.vimrc /etc/skel
cp -rfd .config/.Xresources /etc/skel
cp -rfd .config/.nanorc /etc/skel
mv .config/.gmrunrc /root
mv .config/.gtkrc-2.0 /root/.gtkrc-2.0
mv .config/.fonts.conf /root
mv .config/.gtk-bookmarks /root
mv .config/.vimrc /root
mv .config/.Xresources /root
mv .config/.nanorc /root
mv .config/default-tile.png /usr/share/backgrounds/default-tile.png
rm -rfd /usr/share/lxdm/themes
cp -rfd .config/themes /usr/share/lxdm
mv .config/lxdm.conf /etc/lxdm
rm -rfd /usr/share/icons/CBPP*
cp -rfd .config/CBPP /usr/share/icons
cp -rfd .config/openbox-3 /usr/share/themes/CBPP
mkdir -p /usr/share/icons/default
cp -rfd .config/CBPP/index.theme /usr/share/icons/default
cp -rfd .config/.newsboat /home/$MY_USERNAME/.newsboat
cp -rfd .config/.newsboat /etc/skel/.newsboat
cp -rfd .config/.newsboat /root/.newsboat
cp -rfd .config/.local/* /home/$MY_USERNAME/.local
cp -rfd .config/.local/* /etc/skel/.local
cp -rfd .config/* /home/$MY_USERNAME/.config
cp -rfd .config/* /etc/skel/.config
cp -rfd .config/* /root/.config
chown -hR $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.*
chown -hR $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/*
find /home/$MY_USERNAME/.config/ | egrep '\CBPP' | xargs rm -rfd
find /etc/skel/.config/ | egrep '\CBPP' | xargs rm -rfd
find /root/.config/ | egrep '\CBPP' | xargs rm -rfd
find /home/$MY_USERNAME/.config/ | egrep '\themes' | xargs rm -rfd
find /etc/skel/.config/ | egrep '\themes' | xargs rm -rfd
find /root/.config/ | egrep '\themes' | xargs rm -rfd
find /home/$MY_USERNAME/.config/ | egrep '\openbox-3' | xargs rm -rfd
find /etc/skel/.config/ | egrep '\openbox-3' | xargs rm -rfd
find /root/.config/ | egrep '\openbox-3' | xargs rm -rfd
find /home/$MY_USERNAME/.config/ | egrep '\cbpp' | xargs rm -f
find /root/.config/ | egrep '\cbpp' | xargs rm -f
find /usr/bin/ | egrep '\cbpp' | xargs rm -f
find /usr/bin/ | egrep '\conkywonky' | xargs rm -f
find /usr/bin/ | egrep '\tint2restart' | xargs rm -f

sed -i -e "s/# autologin=.*/autologin=$MY_USERNAME/g" /etc/lxdm/lxdm.conf

# Other stuff you should do
if [ "$MY_INIT" = "openrc" ]; then
  rc-update add connmand default
  rc-update add lxdm default
  rc-update add pipewire default
  rc-update add wireplumber default
elif [ "$MY_INIT" = "runit" ]; then
  ln -s /etc/runit/sv/connmand/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/lxdm/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/pipewire/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/wireplumber/ /etc/runit/runsvdir/current
fi

if [ "$ENCRYPTED" = "y" ]; then
  if [ "$MY_FS" = "btrfs" ]; then
  mkdir /root/.keyfiles
  chmod 0400 /root/.keyfiles
  dd if=/dev/urandom of=/root/.keyfiles/main bs=1024 count=4
  yes "$CRYPTPASS" | cryptsetup luksAddKey "$ROOT_PART" /root/.keyfiles/main
  echo -e "dmcrypt_key_timeout=1
dmcrypt_retries=5
key='/root/.keyfiles/main'" >/etc/conf.d/dmcrypt
  fi
  [ "$MY_INIT" = "openrc" ] && rc-update add dmcrypt boot
  [ "$MY_INIT" = "runit" ] && ln -s /etc/runit/sv/dmcrypt/ /etc/runit/runsvdir/current
fi

# Configure mkinitcpio
if [ "$ENCRYPTED" = "y" ]; then
  sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/g' /etc/mkinitcpio.conf
else
  sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block filesystems fsck)/g' /etc/mkinitcpio.conf
fi

if [ "$MY_FS" = "btrfs" ]; then
  sed -i -e 's/BINARIES=()/BINARIES=(\/usr\/bin\/btrfs)/g' /etc/mkinitcpio.conf
fi

mkinitcpio -P

# Install boot loader
if [ "$ENCRYPTED" = "y" ]; then
  DRIVE_UUID=$(blkid "$PART2" -o value -s UUID)
  ROOT_UUID=$(blkid "$ROOT_PART" -o value -s UUID)
  sed -i -e "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$DRIVE_UUID:root root=UUID=$ROOT_UUID quiet\"/g" /etc/default/grub
  sed -i -e '/GRUB_ENABLE_CRYPTODISK=y/s/^#//g' /etc/default/grub
fi

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg
