# X96 OS

A fast, clean Linux for the **X96 Mini** TV box (Amlogic S905W, 2 GB RAM): a macOS-styled **desktop** edition and a lean **command-line** edition.
Flash it to an SD card or USB stick and boot. No renaming files, no editing `uEnv.txt`.

## Two editions

| | **Desktop** | **CLI** |
|---|---|---|
| For | Using the box as a small computer on your TV | Headless server: Pi-hole, Home Assistant, file server, SSH box |
| Interface | macOS-style Xfce desktop, auto-login | Console + SSH, colourful X96 OS greeting with live system info |
| Apps | Firefox, LibreOffice, Celluloid, files, terminal | `htop`, `btop`, `tmux`, `git`, `nmtui`, `x96os` helper |
| RAM at idle | ~450 MB | ~100 MB |
| File | `X96OS-*-desktop-*.img.xz` | `X96OS-*-cli-*.img.xz` |

Both share the same tuned base: X96 Mini boot setup, Wi-Fi drivers, zram, CPU/IO/IRQ tuning.

## What's inside

| | |
|---|---|
| Base | Debian 13 "trixie" (Armbian userspace, [ophub](https://github.com/ophub/amlogic-s9xxx-armbian) kernel 6.12 LTS) |
| Boot | Pre-configured for the X96 Mini: `meson-gxl-s905w-x96-mini.dtb` and boot scripts already in place |
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
- **All 4 cores share the network work** (RPS/RFS) and storage/Ethernet interrupts are moved off CPU0.
- **CLI edition:** BBR + fq TCP tuning, Bluetooth off by default, lowest CPU clock allowed at idle, big Terminus console font readable on a TV.

### The `x96os` command (both editions)
```
x96os            system overview          x96os update    update all software
x96os wifi       connect to Wi-Fi         x96os kernel    update the kernel
x96os install    install to internal eMMC x96os temp      live temperature + clocks
x96os backup     back up internal storage x96os tune      show performance settings
x96os report     bug report with hardware info + logs
```

## Install

1. Download the edition you want (`X96OS-*-desktop-*.img.xz` or `X96OS-*-cli-*.img.xz`) from [**Releases**](../../releases).
2. Flash it to a microSD card or USB stick (8 GB or larger) with [balenaEtcher](https://etcher.balena.io/) or Rufus. No need to unzip.
3. **First boot from the card (only once):** unplug the box, insert the card, push a toothpick into the AV jack to hold the hidden reset button, plug in power, release after ~5 seconds when the logo appears.
4. The desktop edition logs in automatically. On the CLI edition, log in on the TV or over SSH (`ssh x96@<ip shown on screen>`).

| | |
|---|---|
| User | `x96` |
| Password | `x96os` (also the `root` password, change both with `passwd` and `sudo passwd`) |

### Run from internal storage (optional)
Once you're happy, install to the eMMC for more speed. **This erases Android.** Back it up first with `x96os backup`.
```
x96os install
```
Choose **113 : X96-Mini**, wait, shut down, remove the card, power on.

## Testing without the box
Every build is boot-tested automatically in QEMU as a "virtual X96 Mini" (same CPU type, RAM and kernel) before it is
published; results and a screenshot are on the [`build-status` branch](../../tree/build-status).
You can run any image the same way on your own PC: see **[docs/TESTING.md](docs/TESTING.md)**.
Found a bug? Run `x96os report` and attach the file to an [issue](../../issues).

## Tips
- **Super** key: app menu · **Super+Space**: search · **Super+E**: files · **Super+T**: terminal
- **YouTube**: the dock's YouTube icon opens it in Firefox. For the smoothest playback, copy a video link and open it in **Celluloid** (＋ → Open Location).
- **Wi-Fi**: click the network icon in the top bar (desktop) or run `x96os wifi` (CLI). If the built-in Wi-Fi chip isn't detected (some X96 Minis use the SSV6051, which has no Linux driver), plug in a USB Wi-Fi dongle.
- **Login screen**: to require a password at startup on the desktop, remove the `autologin-*` lines in `/etc/lightdm/lightdm.conf.d/50-x96os.conf`.
- **4K desktop**: create `/etc/x96os/display.conf` with `X96OS_ALLOW_4K=1`.
- **Bluetooth on the CLI edition**: `sudo systemctl enable --now bluetooth`.
- **Updates**: `x96os update`; kernel updates: `x96os kernel`.

## Building
Every push to `main` builds both editions on GitHub Actions (native arm64 runners, in parallel) and publishes them together under Releases.
- `.github/workflows/build.yml`: thin workflow that runs the steps below for each edition, then publishes one release.
- `scripts/ci-*.sh`: the CI steps (prepare runner, find the Armbian base, build, boot test, release, status report).
- `scripts/build-image.sh`: unpack → themes and artwork → chroot customisation → shrink → compress.
- `scripts/customize-chroot.sh`: packages, drivers, users, desktop layout, services (per edition).
- `scripts/run-qemu.sh` / `run-qemu.bat`: run an image on a PC (see docs/TESTING.md).
- `overlay/` (desktop + shared system tuning), `overlay-common/` (both editions), `overlay-cli/`: config files copied into the image.
- `assets/make-wallpapers.py`: generates the logo and wallpapers.

Build status of the last run: [`build-status` branch](../../tree/build-status).

## Credits
[ophub/amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian) (Amlogic packaging and kernels), [Armbian](https://www.armbian.com/), [Debian](https://www.debian.org/), [WhiteSur themes](https://github.com/vinceliuice) by vinceliuice, [rtl8189ES_linux](https://github.com/jwrdegoede/rtl8189ES_linux) by Hans de Goede, [yt-dlp](https://github.com/yt-dlp/yt-dlp).
