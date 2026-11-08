# X96 OS build status

- run: 24 (id 42501275205), commit 20f2ed6e7ef0b420fba501e59baa75ccd60edbc5
- finished: 2026-11-08 17:11 UTC
- build jobs: success
- release: success

## cli
```
edition: cli
prep: success
base image: success
ophub packaging: success
x96os build: success
```
```
Using base image: Armbian_26.11.0-trunk_trixie_arm64_6.18.62.img.gz
```
### boot test (QEMU virtual X96 Mini)
```
== X96 OS smoke test: X96OS-1.0-cli-x96mini-s905w-20261108.img.xz
QEMU CPU mode: -accel tcg,thread=multi -cpu cortex-a53 (timings below are emulated, the real box is faster)
PASS  boots to login in 62s (emulated CPU, seen via ssh)
PASS  SSH login with the default account
armbian-firstrun: active
PASS  systemd state: running

---- system ----
X96OS_VERSION=1.0
X96OS_BUILD_DATE=2026-11-08
X96OS_DEVICE="X96 Mini (Amlogic S905W)"
X96OS_EDITION=cli
X96OS_KERNEL=6.12.116-ophub
6.12.116-ophub
PASS  no failed services
PASS  sudo works
PASS  first boot grew the root filesystem to 16G
PASS  first-boot setup finished
PASS  edition marker: cli
PASS  no password-less console login
PASS  login greeting is the X96 OS one
PASS  network (eth0) up via NetworkManager
PASS  NetworkManager connected
PASS  DNS works

---- drivers & firmware (in the image) ----
PASS  Wi-Fi driver 8189es.ko present for 6.12.116-ophub
PASS  Wi-Fi driver 8189fs.ko present for 6.12.116-ophub
PASS  Wi-Fi driver 8189es loads into kernel 6.12.116-ophub
PASS  Wi-Fi driver 8189fs loads into kernel 6.12.116-ophub
  dmesg: [    0.658189] raid6: int64x4  gen()  2295 MB/s
  dmesg: [    1.548189] usbserial: USB Serial support registered for cp210x
  dmesg: [  154.312992] 8189es: loading out-of-tree module taints kernel.
  dmesg: [  154.358558] RTW: rtl8189es v5.8.9_35085.20190919
  dmesg: [  159.660234] RTW: rtl8189fs v5.7.9_35795.20191128
  ok     module brcmfmac
  ok     module rtw88_8723ds
  ok     module rtw88_8821cs
  ok     module rtw88_8822bs
  ok     module ath9k_htc
  ok     module mt7601u
  ok     module rt2800usb
  ok     module rtl8xxxu
  ok     module mt76x2u
  ok     module lima
  ok     module meson_vdec
  /lib/firmware/brcm/brcmfmac43455-sdio.bin
  /lib/firmware/meson/vdec/gxl_h264.bin
  /lib/firmware/rtlwifi/rtl8188eufw.bin

---- tuning ----
  none mq-deadline kyber [bfq] 
  100
  bbr
  /dev/zram0 partition 1.4G 0B 5
  32768
PASS  zram swap active
PASS  BFQ I/O scheduler
PASS  earlyoom running
PASS  BBR congestion control

---- memory at idle (2 GB box) ----
               total        used        free      shared  buff/cache   available
Mem:            1971         323        1596          28         208        1647
Swap:           1478           0        1478
RAM used at idle: 321 MiB
  RSS COMMAND
18888 NetworkManager
14256 systemd
13644 systemd-resolve
12176 systemd
10304 sshd-session
 9772 systemd-journal
 9444 systemd-udevd
 8812 systemd-logind
 7396 sshd
 7128 sshd-session
 6532 wpa_supplicant

---- boot time (emulated CPU) ----
Startup finished in 15.132s (kernel) + 1min 33.802s (userspace) = 1min 48.934s 
multi-user.target reached after 1min 33.477s in userspace.
24.615s console-setup.service
23.531s x96os-firstboot.service
18.968s dev-zram1.device
18.913s dev-zram0.device
10.933s NetworkManager.service
10.689s lm-sensors.service
10.216s rng-tools-debian.service
10.047s chrony.service
 9.959s x96os-audio.service
 9.379s rsyslog.service

---- greeting ----
  ██╗  ██╗ █████╗  ██████╗      ██████╗ ███████╗
  ╚██╗██╔╝██╔══██╗██╔════╝     ██╔═══██╗██╔════╝
   ╚███╔╝ ╚██████║███████╗     ██║   ██║███████╗
   ██╔██╗  ╚═══██║██╔═══██╗    ██║   ██║╚════██║
  ██╔╝ ██╗ █████╔╝╚██████╔╝    ╚██████╔╝███████║
  ╚═╝  ╚═╝ ╚════╝  ╚═════╝      ╚═════╝ ╚══════╝

  X96 OS 1.0 · cli edition · Debian 13.7 · kernel 6.12.116-ophub
  ────────────────────────────────────────────────
  CPU       4 × Cortex-A53
  Memory    309 MiB / 1.9 GiB used · zram swap 0 / 1478 MiB
  Storage   1.9G / 16G used (13%)
  Network   eth0 10.0.2.15
  Uptime    3m · load 2.08 2.04 0.92

  x96os help  ·  x96os wifi  ·  x96os install
PASS  screenshot saved (screen-cli.png)

RESULT: 22 passed, 0 failed
```
Screenshot: [screen-cli.png](screen-cli.png)
### errors
```
```
### last 150 lines
```
keeping armbian-firmware 26.11.0-trunk
  firmware ok: meson/vdec/gxl_h264.bin
  firmware ok: brcm
  firmware ok: rtlwifi
  firmware ok: mediatek

---------- zram compressed swap ----------
using armbian-zram-config

---------- Built-in Wi-Fi drivers for X96 Mini variants (RTL8189ES / RTL8189FTV) ----------
compiler: ophub GNU toolchain
built 8189es.ko
built 8189fs.ko

---------- Apply X96 OS configuration overlay ----------

---------- Branding ----------
  removing console auto-login: /etc/systemd/system/getty@.service.d/override.conf
  removing console auto-login: /etc/systemd/system/serial-getty@.service.d/override.conf

---------- Locale and time zone ----------
Generating locales (this might take a while)...
  en_US.UTF-8... done
Generation complete.

---------- User account ----------

---------- Services ----------
Created symlink '/etc/systemd/system/default.target' → '/usr/lib/systemd/system/multi-user.target'.
Created symlink '/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service' → '/usr/lib/systemd/system/NetworkManager-wait-online.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/x96os-firstboot.service' → '/etc/systemd/system/x96os-firstboot.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/x96os-tune.service' → '/etc/systemd/system/x96os-tune.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/x96os-audio.service' → '/etc/systemd/system/x96os-audio.service'.
Synchronizing state of earlyoom.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable earlyoom
Reading package lists...
Building dependency tree...
Reading state information...
The following packages were automatically installed and are no longer required:
  distro-info-data python-apt-common python3-apt python3-dbus
  python3-distro-info
Use 'apt autoremove' to remove them.
The following packages will be REMOVED:
  unattended-upgrades*
0 upgraded, 0 newly installed, 1 to remove and 5 not upgraded.
After this operation, 325 kB disk space will be freed.
(Reading database ... dpkg: warning: files list file for package 'linux-image-current-meson64' missing; assuming package has no files currently installed
(Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 37861 files and directories currently installed.)
Removing unattended-upgrades (2.12) ...
Processing triggers for man-db (2.13.1-1) ...
(Reading database ... dpkg: warning: files list file for package 'linux-image-current-meson64' missing; assuming package has no files currently installed
(Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 37821 files and directories currently installed.)
Purging configuration files for unattended-upgrades (2.12) ...

---------- Clean up ----------
Reading package lists...
Building dependency tree...
Reading state information...
The following packages will be REMOVED:
  distro-info-data* python-apt-common* python3-apt* python3-dbus*
  python3-distro-info*
0 upgraded, 0 newly installed, 5 to remove and 5 not upgraded.
After this operation, 1918 kB disk space will be freed.
(Reading database ... dpkg: warning: files list file for package 'linux-image-current-meson64' missing; assuming package has no files currently installed
(Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 37814 files and directories currently installed.)
Removing python3-distro-info (1.13) ...
Removing python3-apt (3.0.0) ...
Removing distro-info-data (0.66+deb13u2) ...
Removing python-apt-common (3.0.0) ...
Removing python3-dbus (1.4.0-1) ...

---------- Build info ----------
X96 OS 1.0 built 2026-11-08 16:48 UTC
Base: Armbian-unofficial 26.11.0-trunk trixie (trixie), kernel 6.12.116-ophub
Edition: cli
Wi-Fi modules added: 8189es.ko 8189fs.ko
Themes: 
Packages installed: 499
Root usage: 2.0G
customize-chroot.sh finished OK

=================== Leaving chroot ===================
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p2    6.1G  1.9G  4.3G  31% /tmp/x96os-work/rootfs
/dev/loop0p1    510M  155M  356M  31% /tmp/x96os-work/rootfs/boot

=================== Shrinking rootfs ===================
e2fsck 1.47.2 (1-Jan-2025)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
ROOTFS: 58623/409600 files (0.1% non-contiguous), 530639/1638400 blocks
blocks: current=1638400 minimum=750033 target=903633 (block size 4096)
resize2fs 1.47.2 (1-Jan-2025)
Resizing the filesystem on /dev/loop0p2 to 903633 (4k) blocks.
The filesystem on /dev/loop0p2 is now 903633 (4k) blocks long.

Disk /tmp/x96os-work/x96os.img: 6.75 GiB, 7251951616 bytes, 14163968 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xe67e76fe

Old situation:

Device                     Boot   Start      End  Sectors  Size Id Type
/tmp/x96os-work/x96os.img1         8192  1054719  1046528  511M  c W95 FAT32 (LBA)
/tmp/x96os-work/x96os.img2      1056768 14163967 13107200  6.3G 83 Linux

/tmp/x96os-work/x96os.img2: 
New situation:
Disklabel type: dos
Disk identifier: 0xe67e76fe

Device                     Boot   Start     End Sectors  Size Id Type
/tmp/x96os-work/x96os.img1         8192 1054719 1046528  511M  c W95 FAT32 (LBA)
/tmp/x96os-work/x96os.img2      1056768 8285831 7229064  3.4G 83 Linux

The partition table has been altered.
e2fsck 1.47.2 (1-Jan-2025)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
ROOTFS: 58623/229376 files (0.1% non-contiguous), 518530/903633 blocks
Model:  (file)
Disk /tmp/x96os-work/x96os.img: 4047MiB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start    End      Size     Type     File system  Flags
 1      4.00MiB  515MiB   511MiB   primary  fat32        lba
 2      516MiB   4046MiB  3530MiB  primary  ext4


=================== Compressing ===================
/home/runner/work/x96-os/x96-os/out/X96OS-1.0-cli-x96mini-s905w-20261108.img: 772.0 MiB / 4046.8 MiB = 0.191, 21 MiB/s, 3:12
total 830M
-rw-r--r-- 1 runner runner 772M Nov  8 16:48 X96OS-1.0-cli-x96mini-s905w-20261108.img.xz
-rw-r--r-- 1 runner runner  110 Nov  8 16:51 X96OS-1.0-cli-x96mini-s905w-20261108.img.xz.sha256
-rw-r--r-- 1 runner runner  220 Nov  8 16:48 x96os-build-info-cli.txt
-rwxr-xr-x 1 runner runner  18M Nov  8 16:46 x96os-qemu-initrd.img
-rwxr-xr-x 1 runner runner  41M Nov  8 16:46 x96os-qemu-vmlinuz

=================== Done: /home/runner/work/x96-os/x96-os/out/X96OS-1.0-cli-x96mini-s905w-20261108.img.xz ===================
```

## desktop
```
edition: desktop
prep: success
base image: success
ophub packaging: success
x96os build: success
```
```
Using base image: Armbian_26.11.0-trunk_trixie_arm64_6.18.62.img.gz
```
### boot test (QEMU virtual X96 Mini)
```
== X96 OS smoke test: X96OS-1.0-desktop-x96mini-s905w-20261108.img.xz
QEMU CPU mode: -accel tcg,thread=multi -cpu cortex-a53 (timings below are emulated, the real box is faster)
PASS  boots to login in 86s (emulated CPU, seen via ssh)
PASS  SSH login with the default account
armbian-firstrun: active
FAIL  systemd state: degraded

---- system ----
X96OS_VERSION=1.0
X96OS_BUILD_DATE=2026-11-08
X96OS_DEVICE="X96 Mini (Amlogic S905W)"
X96OS_EDITION=desktop
X96OS_KERNEL=6.12.116-ophub
6.12.116-ophub
FAIL  failed services: blueman-mechanism.service udisks2.service
  -- journal of blueman-mechanism.service:
                                                    File "<frozen importlib._bootstrap>", line 1387, in _gcd_import
                                                    File "<frozen importlib._bootstrap>", line 1360, in _find_and_load
                                                    File "<frozen importlib._bootstrap>", line 1331, in _find_and_load_unlocked
                                                    File "<frozen importlib._bootstrap>", line 935, in _load_unlocked
                                                    File "<frozen importlib._bootstrap_external>", line 1026, in exec_module
                                                    File "<frozen importlib._bootstrap>", line 488, in _call_with_frames_removed
                                                    File "/usr/lib/python3/dist-packages/blueman/plugins/mechanism/RfKill.py", line 4, in <module>
                                                      from blueman.plugins.applet.KillSwitch import RFKILL_TYPE_BLUETOOTH, RFKILL_OP_CHANGE_ALL
                                                    File "/usr/lib/python3/dist-packages/blueman/plugins/applet/KillSwitch.py", line 24, in <module>
                                                      raise ImportError('Hardware kill switch not found')
                                                  ImportError: Hardware kill switch not found
     Nov 08 16:09:32 x96os systemd[1]: blueman-mechanism.service: start operation timed out. Terminating.
     Nov 08 16:09:32 x96os systemd[1]: blueman-mechanism.service: Failed with result 'timeout'.
     Nov 08 16:09:32 x96os systemd[1]: Failed to start blueman-mechanism.service - Bluetooth management mechanism.
     Nov 08 16:09:32 x96os systemd[1]: blueman-mechanism.service: Consumed 5.585s CPU time, 39.5M memory peak.
  -- journal of udisks2.service:
     Nov 08 16:09:22 x96os systemd[1]: Starting udisks2.service - Disk Manager...
     Nov 08 16:09:23 x96os udisksd[1075]: udisks daemon version 2.10.1 starting
     Nov 08 16:09:31 x96os udisksd[1075]: Acquired the name org.freedesktop.UDisks2 on the system message bus
     Nov 08 16:09:32 x96os systemd[1]: udisks2.service: start operation timed out. Terminating.
     Nov 08 16:09:32 x96os udisksd[1075]: udisks daemon version 2.10.1 exiting
     Nov 08 16:09:32 x96os systemd[1]: udisks2.service: Failed with result 'timeout'.
     Nov 08 16:09:32 x96os systemd[1]: Failed to start udisks2.service - Disk Manager.
     Nov 08 16:09:32 x96os systemd[1]: udisks2.service: Consumed 3.198s CPU time, 6.8M memory peak.
PASS  sudo works
PASS  first boot grew the root filesystem to 16G
PASS  first-boot setup finished
PASS  edition marker: desktop
PASS  no password-less console login
PASS  network (eth0) up via NetworkManager
PASS  NetworkManager connected
PASS  DNS works

---- drivers & firmware (in the image) ----
PASS  Wi-Fi driver 8189es.ko present for 6.12.116-ophub
PASS  Wi-Fi driver 8189fs.ko present for 6.12.116-ophub
PASS  Wi-Fi driver 8189es loads into kernel 6.12.116-ophub
PASS  Wi-Fi driver 8189fs loads into kernel 6.12.116-ophub
  dmesg: [  212.642828] 8189es: loading out-of-tree module taints kernel.
  dmesg: [  212.686782] RTW: rtl8189es v5.8.9_35085.20190919
  dmesg: [  219.616379] RTW: rtl8189fs v5.7.9_35795.20191128
  ok     module brcmfmac
  ok     module rtw88_8723ds
  ok     module rtw88_8821cs
  ok     module rtw88_8822bs
  ok     module ath9k_htc
  ok     module mt7601u
  ok     module rt2800usb
  ok     module rtl8xxxu
  ok     module mt76x2u
  ok     module lima
  ok     module meson_vdec
  /lib/firmware/brcm/brcmfmac43455-sdio.bin
  /lib/firmware/meson/vdec/gxl_h264.bin
  /lib/firmware/rtlwifi/rtl8188eufw.bin

---- tuning ----
  none mq-deadline kyber [bfq] 
  100
  bbr
  /dev/zram0 partition 1.4G 0B 5
  32768
PASS  zram swap active
PASS  BFQ I/O scheduler
PASS  earlyoom running

---- desktop ----
PASS  LightDM running
PASS  Xorg running
PASS  auto-login into Xfce as x96
PASS  top bar (xfce4-panel) running
PASS  dock running
PASS  desktop/wallpaper (xfdesktop) running

---- memory at idle (2 GB box) ----
               total        used        free      shared  buff/cache   available
Mem:            1971         590        1068          46         490        1380
Swap:           1478           0        1478
RAM used at idle: 588 MiB
  RSS COMMAND
132768 Xorg
115936 xfwm4
81748 xfce4-session
47876 xfdesktop
46524 nm-applet
46308 wrapper-2.0
43316 plank
43048 wrapper-2.0
42700 xfce4-notifyd
33284 xfce4-panel
32156 wrapper-2.0

---- boot time (emulated CPU) ----
Startup finished in 17.997s (kernel) + 1min 34.678s (userspace) = 1min 52.675s 
graphical.target reached after 1min 34.673s in userspace.
24.376s x96os-firstboot.service
14.464s dev-zram0.device
13.254s dev-sda2.device
12.610s dev-zram1.device
12.216s console-setup.service
11.992s blueman-mechanism.service
10.424s udisks2.service
 9.810s NetworkManager.service
 7.814s ldconfig.service
 7.257s polkit.service
PASS  screenshot saved (screen-desktop.png)

---- desktop tour (clicks on the virtual screen, 1920x1080) ----
  screenshot: screen-desktop-menu.png
PASS  clicking Files in the dock opens it (4s, emulated CPU)
  screenshot: screen-desktop-files.png
PASS  clicking Firefox in the dock opens it (3s, emulated CPU)
  screenshot: screen-desktop-firefox.png
  RAM with Firefox open: 903 MiB used
PASS  clicking LibreOffice Writer in the dock opens it (40s, emulated CPU)
  screenshot: screen-desktop-writer.png
PASS  clicking Terminal in the dock opens it (3s, emulated CPU)
  screenshot: screen-desktop-terminal.png
PASS  clicking Settings in the dock opens it (3s, emulated CPU)
  screenshot: screen-desktop-settings.png

RESULT: 29 passed, 2 failed
```
Screenshot: [screen-desktop-files.png](screen-desktop-files.png)
Screenshot: [screen-desktop-firefox.png](screen-desktop-firefox.png)
Screenshot: [screen-desktop-menu.png](screen-desktop-menu.png)
Screenshot: [screen-desktop-settings.png](screen-desktop-settings.png)
Screenshot: [screen-desktop-terminal.png](screen-desktop-terminal.png)
Screenshot: [screen-desktop-writer.png](screen-desktop-writer.png)
Screenshot: [screen-desktop.png](screen-desktop.png)
### errors
```
```
### last 150 lines
```
built 8189fs.ko

---------- Apply X96 OS configuration overlay ----------

---------- Branding ----------
  removing console auto-login: /etc/systemd/system/getty@.service.d/override.conf
  removing console auto-login: /etc/systemd/system/serial-getty@.service.d/override.conf

---------- Locale and time zone ----------
Generating locales (this might take a while)...
  en_US.UTF-8... done
Generation complete.

---------- User account ----------

---------- Desktop defaults ----------
dock: plank
shortcuts updated
Exec=sh -c "ls -d /sys/class/bluetooth/hci* >/dev/null 2>&1 && exec blueman-applet"

---------- Firefox tuning ----------

---------- System settings databases ----------

---------- Services ----------
Created symlink '/etc/systemd/system/default.target' → '/usr/lib/systemd/system/graphical.target'.
Synchronizing state of lightdm.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable lightdm
Created symlink '/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service' → '/usr/lib/systemd/system/NetworkManager-wait-online.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/x96os-firstboot.service' → '/etc/systemd/system/x96os-firstboot.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/x96os-tune.service' → '/etc/systemd/system/x96os-tune.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/x96os-audio.service' → '/etc/systemd/system/x96os-audio.service'.
Synchronizing state of earlyoom.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable earlyoom
Reading package lists...
Building dependency tree...
Reading state information...
The following packages were automatically installed and are no longer required:
  distro-info-data python-apt-common python3-apt python3-dbus
  python3-distro-info
Use 'apt autoremove' to remove them.
The following packages will be REMOVED:
  unattended-upgrades*
0 upgraded, 0 newly installed, 1 to remove and 5 not upgraded.
After this operation, 325 kB disk space will be freed.
(Reading database ... dpkg: warning: files list file for package 'linux-image-current-meson64' missing; assuming package has no files currently installed
(Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 71626 files and directories currently installed.)
Removing unattended-upgrades (2.12) ...
Processing triggers for man-db (2.13.1-1) ...
(Reading database ... dpkg: warning: files list file for package 'linux-image-current-meson64' missing; assuming package has no files currently installed
(Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 71586 files and directories currently installed.)
Purging configuration files for unattended-upgrades (2.12) ...

---------- Clean up ----------
Reading package lists...
Building dependency tree...
Reading state information...
The following packages will be REMOVED:
  distro-info-data* python-apt-common* python3-apt* python3-dbus*
  python3-distro-info*
0 upgraded, 0 newly installed, 5 to remove and 5 not upgraded.
After this operation, 1918 kB disk space will be freed.
(Reading database ... dpkg: warning: files list file for package 'linux-image-current-meson64' missing; assuming package has no files currently installed
(Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 71579 files and directories currently installed.)
Removing python3-distro-info (1.13) ...
Removing python3-apt (3.0.0) ...
Removing distro-info-data (0.66+deb13u2) ...
Removing python-apt-common (3.0.0) ...
Removing python3-dbus (1.4.0-1) ...

---------- Build info ----------
X96 OS 1.0 built 2026-11-08 16:50 UTC
Base: Armbian-unofficial 26.11.0-trunk trixie (trixie), kernel 6.12.116-ophub
Edition: desktop
Dock: plank
Wi-Fi modules added: 8189es.ko 8189fs.ko
Themes: WhiteSur-gtk-theme d578265 WhiteSur-icon-theme 73d8040 WhiteSur-cursors e190baf 
Packages installed: 1105
Root usage: 4.0G
customize-chroot.sh finished OK

=================== Leaving chroot ===================
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p2    6.1G  3.9G  2.3G  63% /tmp/x96os-work/rootfs
/dev/loop0p1    510M  155M  356M  31% /tmp/x96os-work/rootfs/boot

=================== Shrinking rootfs ===================
e2fsck 1.47.2 (1-Jan-2025)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
ROOTFS: 142247/409600 files (0.1% non-contiguous), 1046222/1638400 blocks
blocks: current=1638400 minimum=1454238 target=1607838 (block size 4096)
resize2fs 1.47.2 (1-Jan-2025)
Resizing the filesystem on /dev/loop0p2 to 1607838 (4k) blocks.
The filesystem on /dev/loop0p2 is now 1607838 (4k) blocks long.

Disk /tmp/x96os-work/x96os.img: 6.75 GiB, 7251951616 bytes, 14163968 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x38c9c09d

Old situation:

Device                     Boot   Start      End  Sectors  Size Id Type
/tmp/x96os-work/x96os.img1         8192  1054719  1046528  511M  c W95 FAT32 (LBA)
/tmp/x96os-work/x96os.img2      1056768 14163967 13107200  6.3G 83 Linux

/tmp/x96os-work/x96os.img2: 
New situation:
Disklabel type: dos
Disk identifier: 0x38c9c09d

Device                     Boot   Start      End  Sectors  Size Id Type
/tmp/x96os-work/x96os.img1         8192  1054719  1046528  511M  c W95 FAT32 (LBA)
/tmp/x96os-work/x96os.img2      1056768 13919471 12862704  6.1G 83 Linux

The partition table has been altered.
e2fsck 1.47.2 (1-Jan-2025)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
ROOTFS: 142247/409600 files (0.1% non-contiguous), 1046222/1607838 blocks
Model:  (file)
Disk /tmp/x96os-work/x96os.img: 6798MiB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start    End      Size     Type     File system  Flags
 1      4.00MiB  515MiB   511MiB   primary  fat32        lba
 2      516MiB   6797MiB  6281MiB  primary  ext4


=================== Compressing ===================
/home/runner/work/x96-os/x96-os/out/X96OS-1.0-desktop-x96mini-s905w-20261108.img: 1737.5 MiB / 6797.6 MiB = 0.256, 14 MiB/s, 7:51
total 1.8G
-rw-r--r-- 1 runner runner 1.7G Nov  8 16:50 X96OS-1.0-desktop-x96mini-s905w-20261108.img.xz
-rw-r--r-- 1 runner runner  114 Nov  8 16:58 X96OS-1.0-desktop-x96mini-s905w-20261108.img.xz.sha256
-rw-r--r-- 1 runner runner  317 Nov  8 16:50 x96os-build-info-desktop.txt
-rwxr-xr-x 1 runner runner  18M Nov  8 16:47 x96os-qemu-initrd.img
-rwxr-xr-x 1 runner runner  41M Nov  8 16:47 x96os-qemu-vmlinuz

=================== Done: /home/runner/work/x96-os/x96-os/out/X96OS-1.0-desktop-x96mini-s905w-20261108.img.xz ===================
```
