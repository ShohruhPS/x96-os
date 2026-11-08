# Third-party software in X96 OS images

The X96 OS disk image bundles software made by others. Each part keeps its own license.
The MIT license in [LICENSE](LICENSE) only covers this repository's own files
(build scripts, configuration, logo and wallpapers).

Source code for the GPL-licensed and other open-source parts is available from:

| Component | License | Source |
|---|---|---|
| Debian 13 "trixie" packages (desktop, apps, tools) | Various (GPL, LGPL, MPL, MIT, ...) | https://sources.debian.org and `apt source <package>` on the device |
| Armbian userspace and tools | GPL-2.0 | https://github.com/armbian/build |
| Linux kernel (ophub builds) | GPL-2.0 | https://github.com/ophub/kernel and https://github.com/unifreq/linux-6.12.y |
| Amlogic packaging, boot scripts, `armbian-install` / `armbian-update` | GPL-2.0 | https://github.com/ophub/amlogic-s9xxx-armbian |
| U-Boot binaries | GPL-2.0 | https://source.denx.de/u-boot/u-boot (via the ophub repository above) |
| WhiteSur GTK theme | MIT | https://github.com/vinceliuice/WhiteSur-gtk-theme |
| WhiteSur icon theme | GPL-3.0 | https://github.com/vinceliuice/WhiteSur-icon-theme |
| WhiteSur cursors | GPL-3.0 | https://github.com/vinceliuice/WhiteSur-cursors |
| RTL8189ES / RTL8189FS Wi-Fi drivers | GPL-2.0 | https://github.com/jwrdegoede/rtl8189ES_linux |
| yt-dlp | Unlicense | https://github.com/yt-dlp/yt-dlp |
| Firefox ESR | MPL-2.0 (Debian package) | https://sources.debian.org/src/firefox-esr/ |
| LibreOffice | MPL-2.0 (Debian package) | https://sources.debian.org/src/libreoffice/ |

The exact versions used in a given image are listed in its release notes and in
`/etc/x96os-build-info.txt` on the device; `dpkg -l` shows every installed package.

If you need a copy of the source for something in an image and cannot find it at the links
above, open an issue in this repository and it will be provided.

"X96" refers to the TV box hardware this system is made for. X96 OS is an independent
project and is not affiliated with the box manufacturer. Firefox is a trademark of the
Mozilla Foundation. The macOS-inspired look comes from the WhiteSur themes and uses no Apple assets.
