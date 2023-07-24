#!/bin/bash -e

# Boring stuff you should probably do
ln -sf /usr/share/zoneinfo/"$REGION_CITY" /etc/localtime
hwclock --systohc

# Localization
echo -e "en_GB.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo -e "LANG=en_GB.UTF-8" >/etc/locale.conf
echo -e "KEYMAP=$MY_KEYMAP" >/etc/vconsole.conf
echo -e "KEYMAP=$MY_KEYMAP" >/etc/environment

# Host stuff
echo -e "$MY_HOSTNAME" >/etc/hostname
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
Server = http://rrtovkpcaxl6s2ommj5tigyxamzxaknasd74ecb5t5cdfnkodirjnwyd.onion/artixlinux/\$arch" | tee -a /etc/pacman.conf

pacman -Sy --noconfirm artix-keyring artix-archlinux-support
echo -e "[extra]
Include = /etc/pacman.d/mirrorlist-arch" | tee -a /etc/pacman.conf
pacman -Sy && pacman-key --init && pacman-key --populate archlinux

# System
pacman -Sy --noconfirm curl git lxdm-$MY_INIT mesa openbox pipewire procps psmisc wayland wget wireplumber xdg-utils xdg-user-dirs xorg

# Pull my dotfiles
cd /tmp
git clone --branch $release https://github.com/CBPP/cbpp-ui-theme.git
sudo rm -rfd /usr/share/themes/CBPP*
sudo rm -rfd cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/CBPP/xf*
sudo cp -rfd cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes
sudo rm -rfd /usr/share/backgrounds
sudo mkdir -p /usr/share/backgrounds
git clone --branch artix https://github.com/YurinDoctrine/.config.git
sudo rm -rfd $HOME/.*
sudo rm -rfd /etc/skel/.*
sudo rm -rfd /root/.*
sudo rmdir -p $HOME/*
sudo rmdir -p /etc/skel/*
sudo rmdir -p /root/*
sudo mkdir -p $HOME/.config
sudo mkdir -p /etc/skel/.config
sudo mkdir -p /root/.config
sudo mkdir -p $HOME/.local
sudo mkdir -p /etc/skel/.local
sudo cp -rfd .config/.gmrunrc $HOME
sudo cp -rfd .config/.gtkrc-2.0 $HOME/.gtkrc-2.0
sudo cp -rfd .config/.fonts.conf $HOME
sudo cp -rfd .config/.gtk-bookmarks $HOME
sudo cp -rfd .config/.vimrc $HOME
sudo cp -rfd .config/.Xresources $HOME
sudo cp -rfd .config/.nanorc $HOME
sudo cp -rfd .config/.gmrunrc /etc/skel
sudo cp -rfd .config/.gtkrc-2.0 /etc/skel/.gtkrc-2.0
sudo cp -rfd .config/.fonts.conf /etc/skel
sudo cp -rfd .config/.gtk-bookmarks /etc/skel
sudo cp -rfd .config/.vimrc /etc/skel
sudo cp -rfd .config/.Xresources /etc/skel
sudo cp -rfd .config/.nanorc /etc/skel
sudo mv .config/.gmrunrc /root
sudo mv .config/.gtkrc-2.0 /root/.gtkrc-2.0
sudo mv .config/.fonts.conf /root
sudo mv .config/.gtk-bookmarks /root
sudo mv .config/.vimrc /root
sudo mv .config/.Xresources /root
sudo mv .config/.nanorc /root
sudo mv .config/default-tile.png /usr/share/backgrounds/default-tile.png
sudo rm -rfd /usr/share/lxdm/themes
sudo cp -rfd .config/themes /usr/share/lxdm
sudo mv .config/default.conf /etc/lxdm
sudo rm -rfd /usr/share/icons/CBPP*
sudo cp -rfd .config/CBPP /usr/share/icons
sudo cp -rfd .config/openbox-3 /usr/share/themes/CBPP
sudo mkdir -p /usr/share/icons/default
sudo cp -rfd .config/CBPP/index.theme /usr/share/icons/default
sudo cp -rfd .config/.newsboat $HOME/.newsboat
sudo cp -rfd .config/.newsboat /etc/skel/.newsboat
sudo cp -rfd .config/.newsboat /root/.newsboat
sudo cp -rfd .config/.local/* $HOME/.local
sudo cp -rfd .config/.local/* /etc/skel/.local
sudo cp -rfd .config/* $HOME/.config
sudo cp -rfd .config/* /etc/skel/.config
sudo cp -rfd .config/* /root/.config
sudo chown -hR $USER:$USER /home/$USER/.*
sudo chown -hR $USER:$USER /home/$USER/*
sudo find $HOME/.config/ | egrep '\CBPP' | xargs sudo rm -rfd
sudo find /etc/skel/.config/ | egrep '\CBPP' | xargs sudo rm -rfd
sudo find /root/.config/ | egrep '\CBPP' | xargs sudo rm -rfd
sudo find $HOME/.config/ | egrep '\themes' | xargs sudo rm -rfd
sudo find /etc/skel/.config/ | egrep '\themes' | xargs sudo rm -rfd
sudo find /root/.config/ | egrep '\themes' | xargs sudo rm -rfd
sudo find $HOME/.config/ | egrep '\openbox-3' | xargs sudo rm -rfd
sudo find /etc/skel/.config/ | egrep '\openbox-3' | xargs sudo rm -rfd
sudo find /root/.config/ | egrep '\openbox-3' | xargs sudo rm -rfd
sudo find $HOME/.config/ | egrep '\cbpp' | xargs sudo rm -f
sudo find /root/.config/ | egrep '\cbpp' | xargs sudo rm -f
sudo find /usr/bin/ | egrep '\cbpp' | xargs sudo rm -f
sudo find /usr/bin/ | egrep '\conkywonky' | xargs sudo rm -f
sudo find /usr/bin/ | egrep '\tint2restart' | xargs sudo rm -f

# Other stuff you should do
if [ "$MY_INIT"="openrc" ]; then
  rc-update add connmand default
  rc-update add lxdm default
  rc-update add pipewire default
  rc-update add wireplumber default
elif [ "$MY_INIT"="runit" ]; then
  ln -s /etc/runit/sv/connmand/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/lxdm/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/pipewire/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/wireplumber/ /etc/runit/runsvdir/current
fi

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Configure mkinitcpio
if [ "$MY_FS"="btrfs" ]; then
  sed -i -e 's/BINARIES=()/BINARIES=(\/usr\/bin\/btrfs)/g' /etc/mkinitcpio.conf
fi
sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block filesystems fsck)/g' /etc/mkinitcpio.conf

mkinitcpio -P
