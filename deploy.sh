#!/bin/bash -e

# Boring stuff you should probably do now
ln -sf /usr/share/zoneinfo/"$REGION_CITY" /etc/localtime
hwclock --systohc

# Localization
echo -e "LANG=en_GB.UTF8" >>/etc/environment
echo -e "LANGUAGE=en_GB.UTF8" >>/etc/environment
echo -e "LC_ALL=en_GB.UTF8" >>/etc/environment
echo -e "LC_COLLATE=C" >>/etc/environment
echo -e "en_GB.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo -e "LANG=en_GB.UTF-8" >/etc/locale.conf

echo -e "FONT=ter-v22b
FONT_MAP=8859-2" >/etc/vconsole.conf

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

# Pacman
cp -rfd /etc/pacman.conf /etc/pacman.conf.bak

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

echo -e "
# Arch
[extra]
Include = /etc/pacman.d/mirrorlist-arch

#[community]
#Include = /etc/pacman.d/mirrorlist-arch

#[multilib]
#Include = /etc/pacman.d/mirrorlist-arch
" | tee -a /etc/pacman.conf

pacman -Sy && pacman-key --init && pacman-key --populate archlinux

# System
pacman -Sy --noconfirm acpid-$MY_INIT alsa-utils doas gcc git gtk-engines gtk-engine-murrine iwd jemalloc kitty mesa openbox pipewire pipewire-alsa thermald-$MY_INIT unzip wayland wget wireplumber wpa_supplicant xdg-utils xdg-user-dirs xorg xterm

sed -i -e s"/\#ParallelDownloads.*/ParallelDownloads=3/"g /etc/pacman.conf

echo "permit persist :wheel" >/etc/doas.conf

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
mkdir -p /var/cache/libx11/compose
mkdir -p /home/$MY_USERNAME/.compose-cache
touch /home/$MY_USERNAME/.XCompose
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

# Other stuff you should do
sed -i -e 's/#HandleLidSwitch=.*/HandleLidSwitch=suspend/' /etc/elogind/logind.conf
sed -i -e 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' /etc/elogind/logind.conf
sed -i -e 's/#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
sed -i -e 's/#HandlePowerKeyLongPress=.*/HandlePowerKeyLongPress=reboot/' /etc/elogind/logind.conf

echo -e "LD_PRELOAD=/usr/lib/libjemalloc.so
MALLOC_CHECK=0
MALLOC_TRACE=0
MESA_DEBUG=0
LIBGL_DEBUG=0
LIBGL_NO_DRAWARRAYS=1
LIBC_FORCE_NOCHECK=1
HISTCONTROL=ignoreboth:eraseboth
HISTSIZE=0
LESSHISTFILE=-
LESSHISTSIZE=0
LESSSECURE=1
PAGER=less" | tee -a /etc/environment

mkdir -p /etc/modprobe.d
echo -e "blacklist pcspkr
blacklist snd_pcsp
blacklist lpc_ich
blacklist gpio-ich
blacklist iTCO_wdt
blacklist iTCO_vendor_support
blacklist joydev
blacklist mousedev
blacklist mac_hid
blacklist uvcvideo
blacklist parport_pc
blacklist parport
blacklist lp
blacklist ppdev
blacklist sunrpc
blacklist floppy
blacklist arkfb
blacklist aty128fb
blacklist atyfb
blacklist radeonfb
blacklist cirrusfb
blacklist cyber2000fb
blacklist kyrofb
blacklist matroxfb_base
blacklist mb862xxfb
blacklist neofb
blacklist pm2fb
blacklist pm3fb
blacklist s3fb
blacklist savagefb
blacklist sisfb
blacklist tdfxfb
blacklist tridentfb
blacklist vt8623fb
blacklist sp5100-tco
blacklist sp5100_tco
blacklist pcmcia
blacklist yenta_socket
blacklist btusb
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
blacklist n-hdlc
blacklist ax25
blacklist netrom
blacklist x25
blacklist rose
blacklist decnet
blacklist econet
blacklist af_802154
blacklist ipx
blacklist appletalk
blacklist psnap
blacklist p8022
blacklist p8023
blacklist llc
blacklist i2400m
blacklist i2400m_usb
blacklist wimax
blacklist parport
blacklist parport_pc
blacklist cramfs
blacklist freevxfs
blacklist jffs2
blacklist hfs
blacklist hfsplus
blacklist squashfs
blacklist udf
blacklist wl
blacklist ssb
blacklist b43
blacklist b43legacy
blacklist bcma
blacklist bcm43xx
blacklist brcm80211
blacklist brcmfmac
blacklist brcmsmac" | tee /etc/modprobe.d/nomisc.conf

echo -e "options processor ignore_ppc=1" >/etc/modprobe.d/ignore_ppc.conf

echo -e "options drm_kms_helper poll=0" >/etc/modprobe.d/disable-gpu-polling.conf

mkdir -p /etc/modules-load.d
modprobe bfq && echo -e "bfq" >/etc/modules-load.d/bfq.conf
modprobe tcp_bbr2 && echo -e "tcp_bbr2" >/etc/modules-load.d/bbr2.conf || modprobe tcp_bbr && echo -e "tcp_bbr" >/etc/modules-load.d/bbr.conf

mkdir -p /usr/lib/sysctl.d
echo -e "net.core.default_qdisc=fq" >/usr/lib/sysctl.d/99-tcp.conf
modprobe tcp_bbr2 && echo -e "net.ipv4.tcp_congestion_control=bbr2" >>/usr/lib/sysctl.d/99-tcp.conf || modprobe tcp_bbr && echo -e "net.ipv4.tcp_congestion_control=bbr" >>/usr/lib/sysctl.d/99-tcp.conf

mkdir -p /etc/udev/rules.d
echo -e 'ACTION=="add|change", ATTR{queue/scheduler}=="*bfq*", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/scheduler}="bfq"' >/etc/udev/rules.d/60-scheduler.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/iosched/slice_idle}="0", ATTR{queue/iosched/low_latency}="1"' >/etc/udev/rules.d/90-low-latency.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/add_random}=="0"' >/etc/udev/rules.d/10-add-random.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/iostats}="0"' >/etc/udev/rules.d/20-iostats.rules
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*|mmcblk[0-9]*|nvme[0-9]*", ATTR{bdi/read_ahead_kb}="64", ATTR{queue/read_ahead_kb}="64", ATTR{queue/nr_requests}="32"' >/etc/udev/rules.d/70-readahead.rules

if $(find /sys/block/nvme* | egrep -q nvme); then
    echo -e "options nvme_core default_ps_max_latency_us=0" >/etc/modprobe.d/nvme.conf
fi

echo -e "options nf_conntrack nf_conntrack_helper=0" >/etc/modprobe.d/no-conntrack-helper.conf

sed -i -e 's| rw,relatime| rw,lazytime,relatime,commit=3600,delalloc,nobarrier,nofail,discard|g' /etc/fstab

echo -e "@realtime - rtprio 99
@realtime - memlock unlimited" >>/etc/security/limits.conf

sed -i -e s"/\setxkbmap replaceme &/setxkbmap $MY_KEYMAP &/"g /home/$MY_USERNAME/openbox/autostart

if [ "$MY_INIT" = "openrc" ]; then
  echo -e 'rc_parallel="YES"
rc_interactive="NO"
rc_logger="NO"
rc_send_sigkill="YES"
rc_send_sighup="YES"
rc_timeout_stopsec="10"
SSD_NICELEVEL="-19"' >/etc/rc.conf

  rc-update add connmand default
  rc-update add acpid default
  rc-update add thermald default
elif [ "$MY_INIT" = "runit" ]; then
  ln -s /etc/runit/sv/connmand/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/acpid/ /etc/runit/runsvdir/current
  ln -s /etc/runit/sv/thermald/ /etc/runit/runsvdir/current
fi

if [ "$ENCRYPTED" = "y" ]; then
  if [ "$MY_FS" = "btrfs" ]; then
  mkdir -p /root/.keyfiles
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
  sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect modconf block encrypt keyboard keymap filesystems fsck)/g' /etc/mkinitcpio.conf
else
  sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect modconf block keyboard keymap filesystems fsck)/g' /etc/mkinitcpio.conf
fi

if [ "$MY_FS" = "btrfs" ]; then
  sed -i -e 's/BINARIES=()/BINARIES=(\/usr\/bin\/btrfs)/g' /etc/mkinitcpio.conf
fi

sed -i -e 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/g' /etc/mkinitcpio.conf
sed -i -e 's/#COMPRESSION_OPTIONS=.*/COMPRESSION_OPTIONS=("--best")/g' /etc/mkinitcpio.conf

mkinitcpio -P

# Install boot loader
if [ "$ENCRYPTED" = "y" ]; then
  DRIVE_UUID=$(blkid "$PART2" -o value -s UUID)
  ROOT_UUID=$(blkid "$ROOT_PART" -o value -s UUID)
  sed -i -e "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$DRIVE_UUID:root root=UUID=$ROOT_UUID quiet rootfstype=ext4,btrfs,xfs,f2fs biosdevname=0 nowatchdog noautogroup noresume default_hugepagesz=1G hugepagesz=1G zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=zsmalloc workqueue.power_efficient=1 pci=pcie_bus_perf,noaer rd.plymouth=0 plymouth.enable=0 plymouth.ignore-serial-consoles logo.nologo consoleblank=0 vt.global_cursor_default=0 rd.systemd.show_status=auto loglevel=0 rd.udev.log_level=0 udev.log_priority=0 audit=0 nosoftlockup selinux=0 enforcing=0 mce=off no_timer_check skew_tick=1 clocksource=tsc tsc=perfect nohz=on rcu_nocb_poll irqpoll threadirqs irqaffinity=0 noirqdebug kthread_cpus=0 iommu=off sched_policy=1 idle=nomwait noatime boot_delay=0 io_delay=none rootdelay=0 elevator=noop init_on_alloc=0 init_on_free=0 mitigations=off ftrace_enabled=0 fsck.repair=no fsck.mode=skip cgroup_disable=memory cgroup_no_v1=all\"/g" /etc/default/grub
  sed -i -e '/GRUB_ENABLE_CRYPTODISK=y/s/^#//g' /etc/default/grub
else
  sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet rootfstype=ext4,btrfs,xfs,f2fs biosdevname=0 nowatchdog noautogroup noresume default_hugepagesz=1G hugepagesz=1G zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=zsmalloc workqueue.power_efficient=1 pci=pcie_bus_perf,noaer rd.plymouth=0 plymouth.enable=0 plymouth.ignore-serial-consoles logo.nologo consoleblank=0 vt.global_cursor_default=0 rd.systemd.show_status=auto loglevel=0 rd.udev.log_level=0 udev.log_priority=0 audit=0 nosoftlockup selinux=0 enforcing=0 mce=off no_timer_check skew_tick=1 clocksource=tsc tsc=perfect nohz=on rcu_nocb_poll irqpoll threadirqs irqaffinity=0 noirqdebug kthread_cpus=0 iommu=off sched_policy=1 idle=nomwait noatime boot_delay=0 io_delay=none rootdelay=0 elevator=noop init_on_alloc=0 init_on_free=0 mitigations=off ftrace_enabled=0 fsck.repair=no fsck.mode=skip cgroup_disable=memory cgroup_no_v1=all"/' /etc/default/grub
fi

sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i -e 's/GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=0/' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg
