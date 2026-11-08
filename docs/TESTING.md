# Testing X96 OS without the box (QEMU)

X96 OS can run in **QEMU** as a "virtual X96 Mini": same CPU type (4× Cortex-A53), same 2 GB of RAM,
the image attached as a USB stick, and the very same kernel. Good for testing everything that is
*software*. The real box is still needed for the hardware parts.

Every build already does this automatically: before an image is published it is booted in QEMU,
logged into over SSH and checked. The results and a screenshot are on the
[`build-status` branch](../../../tree/build-status).

| Works the same in QEMU | Only testable on the real X96 Mini |
|---|---|
| Boot to desktop / login, first-boot setup, disk growing | Booting from the SD card via the stock bootloader (toothpick reset) |
| Desktop look: theme, dock, top bar, wallpapers, login screen | GPU acceleration (Mali-450 / Lima): QEMU uses a virtual GPU |
| Apps: Firefox, LibreOffice, Celluloid, terminal, settings | Hardware video decoding, HDMI sound |
| CLI greeting, `x96os` command, SSH, shell prompt | Built-in Wi-Fi chip, Bluetooth, IR remote |
| Package updates, `x96os update` | Real speed: on a PC the ARM CPU is *emulated* and slower |
| Bugs in menus, settings, scripts, wording | CPU temperature, clock speeds, `x96os-tune` effects |

## 1. Download from the [Releases](../../../releases) page

- `X96OS-…-desktop-….img.xz` and/or `X96OS-…-cli-….img.xz`
- `x96os-qemu-vmlinuz` and `x96os-qemu-initrd.img`

Put them all in one folder.

## 2. Run it

### Windows
1. Install QEMU and 7-Zip (in a terminal):
   ```
   winget install SoftwareFreedomConservancy.QEMU
   winget install 7zip.7zip
   ```
2. Download [`scripts/run-qemu.bat`](../scripts/run-qemu.bat) into the same folder, then drag the
   `.img.xz` file onto `run-qemu.bat` (or run `run-qemu.bat X96OS-1.0-cli-x96mini-s905w-YYYYMMDD.img.xz`).

### Linux / macOS
```
sudo apt install qemu-system-arm qemu-utils xz-utils     # Debian/Ubuntu
brew install qemu xz                                     # macOS
bash run-qemu.sh X96OS-1.0-desktop-x96mini-s905w-YYYYMMDD.img.xz
```
On an ARM computer (Apple Silicon Mac, ARM Linux with KVM) the script uses hardware
acceleration and the VM runs at full speed.

The first start unpacks the image (a few GB) and grows it to 16 GB. The first boot takes
longer than later ones. On a normal PC the desktop edition is noticeably slower than on the
real box because every ARM instruction is emulated; the CLI edition feels fine.

**Login:** user `x96` with the default password from the README. From your PC you can also SSH in:
`ssh -p 2222 x96@localhost`.

## 3. Report a bug

1. In X96 OS (real box or QEMU), open a terminal and run:
   ```
   x96os report
   ```
   It writes `x96os-report-<date>.txt` in your home folder: board and kernel, CPU, memory,
   storage, Wi-Fi chip ID, USB devices, network, display, audio, failed services and error logs.
   No passwords or Wi-Fi keys are included.
2. Open an [issue](../../../issues/new), say what you did, what you expected and what happened,
   attach the report (and a photo of the screen if it's visual).
3. Say whether it happened on the **real X96 Mini** or in **QEMU**.

To get the report off the box: copy it to a USB stick, or from your PC run
`scp x96@<box-ip>:x96os-report-*.txt .` (QEMU: `scp -P 2222 x96@localhost:x96os-report-*.txt .`).
