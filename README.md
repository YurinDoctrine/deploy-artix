# deploy-artix

## Overview

<p align="center">
  <img src="https://github.com/YurinDoctrine/deploy-artix/blob/main/screenshot.png?raw=true" alt="screenshot" border="0">
</p>

![](https://img.shields.io/badge/Artix%20Linux-grey?logo=Artix+Linux)

_This project aims to provide a smooth **[Artix Linux](https://artixlinux.org)** installation experience, either for beginners or experts who want a reproducable best-practices installation.
It supports only `runit` init system. It also supports `cryptsetup`._

The installer performs the following main steps (in roughly this order),
with some parts depending on the chosen configuration:

1. Configure system (hostname, timezone, keymap, locales, ...)
2. Partition disk
3. Install kernel
4. Install base packages
5. Setup grub
6. Ensure minimal working Artix with [dotfiles](https://github.com/YurinDoctrine/.config/tree/artix)

### Preinstallation

* ISO downloads can be found at [artixlinux.org](https://artixlinux.org/download.php)
* ISO files can be burned to drives with `sudo dd if=/path/to/artix.iso of=/dev/[drive letter] bs=2M status=progress` or something like [Etcher](https://etcher.balena.io).
* A better method these days is to use [Ventoy](https://www.ventoy.net/en/index.html).

### Usage

1. Boot into live environment (both login and password are `artix`).
2. Connect to the internet.

Ethernet is setup automatically and Wi-Fi is setup with something like:
```
sudo rfkill unblock wifi
sudo ip link set wlan0 up
connmanctl # In ConnMan, use respectively: `agent on`, `enable wifi`, `scan wifi`, `services`, `connect wifi_NAME`, `quit`
```
3. Run the script as root:
```
bash <(curl -s https://raw.githubusercontent.com/YurinDoctrine/deploy-artix/main/setup.sh)
```
4. Once all done, `reboot` or `poweroff` and remove the installation media then boot into Artix (post-installation networking is done with wpa_supplicant).

#### References

* [Artix Wiki / Installation](https://wiki.artixlinux.org/Main/Installation)
