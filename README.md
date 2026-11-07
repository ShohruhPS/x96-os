# X96 OS

A fast, clean, macOS-styled Linux desktop for the **X96 Mini** TV box (Amlogic S905W, 2 GB RAM).
Flash it to an SD card or USB stick and boot. No renaming files, no editing `uEnv.txt`.

## What's inside

| | |
|---|---|
| Base | Debian 13 "trixie" (Armbian userspace, [ophub](https://github.com/ophub/amlogic-s9xxx-armbian) kernel 6.12 LTS) |
| Boot | Pre-configured for the X96 Mini: `meson-gxl-s905w-x96-mini.dtb` + `u-boot.ext` already in place |
| Desktop | Xfce with a macOS layout: top menu bar, Plank dock, WhiteSur theme, icons and cursors, traffic-light window buttons |
| Apps | Firefox ESR (+ uBlock Origin), LibreOffice Writer/Calc/Impress, Celluloid media player, Thunar file manager, terminal, text editor, image viewer |
| Video | mpv/Celluloid use the S905W's hardware decoder (H.264, MPEG-2, HEVC, VP9). Paste a YouTube link into Celluloid for smooth hardware-decoded playback (via yt-dlp) |
| Wi-Fi | Drivers for RTL8189ES / RTL8189FTV built-in chips, plus firmware for common USB Wi-Fi / Bluetooth dongles (Realtek, MediaTek, Atheros, Ralink) |

### Tuned for this hardware
- **Desktop capped at 1080p** on 4K TVs: the Mali-450 GPU can't drive a 4K desktop smoothly.
- **"Solid" theme variants** without translucency, so the GPU does less work.
- **zram** compressed swap (zstd), `earlyoom` closes the heaviest tab instead of letting the box freeze.
- **schedutil** CPU governor, **BFQ** I/O scheduler, logs kept in RAM, fewer background services.
- **Firefox** asks YouTube for H.264 instead of VP9/AV1, which is much cheaper to decode on this CPU, and uses fewer processes.

## Install

1. Download `X96OS-*.img.xz` from [**Releases**](../../releases).
2. Flash it to a microSD card or USB stick (8 GB or larger) with [balenaEtcher](https://etcher.balena.io/) or Rufus. No need to unzip.
3. **First boot from the card (only once):** unplug the box, insert the card, push a toothpick into the AV jack to hold the hidden reset button, plug in power, release after ~5 seconds when the logo appears.
4. X96 OS logs in automatically.

| | |
|---|---|
| User | `x96` |
| Password | `x96os` (also the `root` password, change both with `passwd` and `sudo passwd`) |

### Run from internal storage (optional)
Once you're happy, install to the eMMC for more speed. **This erases Android.** Back it up first with `sudo armbian-ddbr`.
```
sudo armbian-install
```
Choose **113 : X96-Mini**, wait, shut down, remove the card, power on.

## Tips
- **Super** key: app menu · **Super+Space**: search · **Super+E**: files · **Super+T**: terminal
- **YouTube**: the dock's YouTube icon opens it in Firefox. For the smoothest playback, copy a video link and open it in **Celluloid** (＋ → Open Location).
- **Wi-Fi**: click the network icon in the top bar. If the built-in Wi-Fi chip isn't detected (some X96 Minis use the SSV6051, which has no Linux driver), plug in a USB Wi-Fi dongle.
- **Login screen**: to require a password at startup, remove the `autologin-*` lines in `/etc/lightdm/lightdm.conf.d/50-x96os.conf`.
- **4K desktop**: create `/etc/x96os/display.conf` with `X96OS_ALLOW_4K=1`.
- **Updates**: `sudo apt update && sudo apt upgrade`; kernel updates: `sudo armbian-update`.

## Building
Every push to `main` builds a new image on GitHub Actions (native arm64 runner) and publishes it under Releases.
- `.github/workflows/build.yml`: downloads the Armbian base, packages it for the X96 Mini with ophub's tools, runs the X96 OS customisation, publishes the release.
- `scripts/build-image.sh`: unpack → themes and artwork → chroot customisation → shrink → compress.
- `scripts/customize-chroot.sh`: packages, drivers, users, desktop layout, services.
- `overlay/`: config files copied into the image.
- `assets/make-wallpapers.py`: generates the logo and wallpapers.

Build status of the last run: [`build-status` branch](../../tree/build-status).

## Credits
[ophub/amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian) (Amlogic packaging and kernels), [Armbian](https://www.armbian.com/), [Debian](https://www.debian.org/), [WhiteSur themes](https://github.com/vinceliuice) by vinceliuice, [rtl8189ES_linux](https://github.com/jwrdegoede/rtl8189ES_linux) by Hans de Goede, [yt-dlp](https://github.com/yt-dlp/yt-dlp).
