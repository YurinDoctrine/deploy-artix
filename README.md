# deploy-artix

This project aims to provide a smooth installation experience, both for beginners and experts.
It also supports both EFI (recommended) and BIOS boot.

This installer also might appeal to you if you already are an expert but want a reproducable best-practices installation.

## Overview

The installer performs the following main steps (in roughly this order),
with some parts depending on the chosen configuration:

1. Base system configuration (hostname, timezone, keymap, locales, ...)
2. Partition disks
3. Install base packages (base, base-devel, ...)
4. Install kernel
5. Install grub
6. Ensure minimal working system with my [dotfiles](https://github.com/YurinDoctrine/.config)

### Preinstallation

* ISO downloads can be found at [artixlinux.org](https://artixlinux.org/download.php)
* ISO files can be burned to drives with `dd` or something like Etcher.
* `sudo dd bs=4M if=/path/to/artix.iso of=/dev/sd[drive letter] status=progress`
* A better method these days is to use [Ventoy](https://www.ventoy.net/en/index.html).

### Usage

1. Boot into live environment (both login and password are `artix`).
2. Connect to the internet. Ethernet is setup automatically, and WiFi is done with something like:
```
sudo rfkill unblock wifi
sudo ip link set wlan0 up
connmanctl # In Connman, use respectively: `agent on`, `scan wifi`, `services`, `connect wifi_NAME`, `quit`
```
3. Clone the repository:
```
sudo pacman -Sy git # Install git in live environment, then clone:

git clone "https://github.com/YurinDoctrine/deploy-artix"
```
4. Run `./setup.sh`.
5. When everything finishes, `reboot` or `poweroff` then remove the installation media and boot into Artix. The post-installation networking is done with Connman.

#### References

* [Artix Wiki Installation](https://wiki.artixlinux.org/Main/Installation)
