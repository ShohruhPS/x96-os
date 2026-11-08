#!/usr/bin/env bash
# CI: boot a freshly built X96 OS image in QEMU ("virtual X96 Mini": 4x Cortex-A53, 2 GB RAM,
# image attached as a USB stick, same kernel), log in over SSH, check it, take a screenshot.
#
#   scripts/ci-smoketest.sh <edition> <out-dir>
#
# Writes logs/smoketest-<edition>.txt, logs/serial-<edition>.log, logs/screen-<edition>.png.
# Exit code: 0 = boots and passes the checks, 1 = failed.
set -uo pipefail
EDITION="$1"; OUT="$2"
LOGS="${GITHUB_WORKSPACE:-$PWD}/logs"; mkdir -p "$LOGS"
REPORT="$LOGS/smoketest-$EDITION.txt"
SERIAL="$LOGS/serial-$EDITION.log"
T="${RUNNER_TEMP:-/tmp}/smoke-$EDITION"; mkdir -p "$T"
SSHP=2222
PW="${X96OS_TEST_PASSWORD:-x96os}"   # default account of the image under test
PASS=0; FAIL=0
say()  { echo "$*" | tee -a "$REPORT"; }
ok()   { say "PASS  $*"; PASS=$((PASS+1)); }
bad()  { say "FAIL  $*"; FAIL=$((FAIL+1)); }
: > "$REPORT"

img_xz="$(ls -1 "$OUT"/X96OS-*-"$EDITION"-*.img.xz 2>/dev/null | head -n1)"
[ -n "$img_xz" ] || { bad "no $EDITION image in $OUT"; exit 1; }
[ -f "$OUT/x96os-qemu-vmlinuz" ] && [ -f "$OUT/x96os-qemu-initrd.img" ] || { bad "QEMU kernel/initrd missing"; exit 1; }
say "== X96 OS smoke test: $(basename "$img_xz")"
xz -dc -T0 "$img_xz" > "$T/disk.img"
qemu-img resize -f raw "$T/disk.img" 16G >/dev/null

ACCEL=(-accel tcg,thread=multi -cpu cortex-a53)
[ -w /dev/kvm ] && ACCEL=(-accel kvm -cpu host)
say "QEMU CPU mode: ${ACCEL[*]} (timings below are emulated, the real box is faster)"

qemu-system-aarch64 -M virt "${ACCEL[@]}" -smp 4 -m 2048 \
  -kernel "$OUT/x96os-qemu-vmlinuz" -initrd "$OUT/x96os-qemu-initrd.img" \
  -append "root=LABEL=ROOTFS rootwait rw console=ttyAMA0 console=tty0 net.ifnames=0 fsck.repair=yes" \
  -device qemu-xhci,id=xhci \
  -drive if=none,id=x96disk,file="$T/disk.img",format=raw \
  -device usb-storage,bus=xhci.0,drive=x96disk \
  -device usb-kbd,bus=xhci.0 -device usb-tablet,bus=xhci.0 \
  -device virtio-gpu-pci,xres=1920,yres=1080 -display none \
  -netdev user,id=net0,hostfwd=tcp::$SSHP-:22 -device virtio-net-pci,netdev=net0 \
  -serial file:"$SERIAL" -monitor unix:"$T/mon.sock",server,nowait \
  -daemonize -pidfile "$T/qemu.pid"
START=$(date +%s)

mon() { printf '%s\n' "$1" | socat - UNIX-CONNECT:"$T/mon.sock" >/dev/null 2>&1; }
SSH=(sshpass -p "$PW" ssh -p $SSHP -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
     -o ConnectTimeout=10 -o LogLevel=ERROR x96@localhost)
cleanup() { mon quit; sleep 2; [ -f "$T/qemu.pid" ] && kill "$(cat "$T/qemu.pid")" 2>/dev/null; rm -f "$T/disk.img"; }
trap cleanup EXIT

# 1. kernel + systemd come up: a login prompt on the serial console, or SSH answering
deadline=$((START + 1500))
up=""
while [ "$(date +%s)" -lt "$deadline" ]; do
  if grep -q "login:" "$SERIAL" 2>/dev/null; then up=serial; break; fi
  if "${SSH[@]}" true 2>/dev/null; then up=ssh; break; fi
  [ -f "$T/qemu.pid" ] && kill -0 "$(cat "$T/qemu.pid")" 2>/dev/null || { bad "QEMU exited"; break; }
  sleep 15
done
if [ -n "$up" ]; then ok "boots to login in $(( $(date +%s) - START ))s (emulated CPU, seen via $up)"
else bad "did not reach a login after $(( $(date +%s) - START ))s"; tail -60 "$SERIAL" | tee -a "$REPORT"; exit 1; fi

# 2. SSH login with the default account
for i in $(seq 1 30); do "${SSH[@]}" true 2>/dev/null && break; sleep 10; done
if "${SSH[@]}" true 2>/dev/null; then ok "SSH login with the default account"
else bad "SSH login failed"; tail -60 "$SERIAL" | tee -a "$REPORT"; exit 1; fi

# admin tools (modinfo, sysctl, swapon, modprobe) live in /usr/sbin, which a normal user's PATH lacks
r() { "${SSH[@]}" "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; $*" 2>&1; }
sr() { r "echo '$PW' | sudo -S -p '' sh -c \"$*\""; }
# let first-boot jobs (disk growing, SSH keys, desktop start) settle
r 'for i in $(seq 1 60); do s=$(systemctl is-system-running 2>/dev/null); case $s in running|degraded) break;; esac; sleep 5; done; echo $s' > "$T/state"
state="$(tail -n1 "$T/state")"
[ "$state" = running ] && ok "systemd state: running" || bad "systemd state: $state"

say ""; say "---- system ----"
r 'cat /etc/x96os-release; uname -r' | tee -a "$REPORT"
failed="$(r 'systemctl --failed --no-legend --plain | awk "{print \$1}"' | xargs)"
if [ -z "$failed" ]; then ok "no failed services"; else
  bad "failed services: $failed"
  for u in $failed; do say "  -- journal of $u:"; sr "journalctl -b -u $u --no-pager -q | tail -n 15" | sed 's/^/     /' | tee -a "$REPORT"; done
fi
r "echo '$PW' | sudo -S -p '' true" >/dev/null && ok "sudo works" || bad "sudo"
grown="$(r 'df -BG --output=size / | tail -1 | tr -dc 0-9')"
[ "${grown:-0}" -ge 12 ] && ok "first boot grew the root filesystem to ${grown}G" || bad "root filesystem not grown (${grown}G)"
r 'test -f /var/lib/x96os/firstboot-done' >/dev/null && ok "first-boot setup finished" || bad "first-boot marker missing"
[ "$(r 'cat /etc/x96os/edition')" = "$EDITION" ] && ok "edition marker: $EDITION" || bad "edition marker wrong"
r 'ip -4 -br addr show eth0' | grep -q UP && ok "network (eth0) up via NetworkManager" || bad "eth0 not up"
r 'nmcli -t -f STATE general' | grep -q connected && ok "NetworkManager connected" || bad "NetworkManager not connected"
r 'getent hosts deb.debian.org' >/dev/null && ok "DNS works" || bad "DNS"

say ""; say "---- drivers & firmware (in the image) ----"
for m in 8189es 8189fs; do
  r "modinfo -F filename $m" | grep -q "\.ko" && ok "Wi-Fi driver $m.ko present for $(r 'uname -r')" || bad "Wi-Fi driver $m missing"
done
# load each built-in Wi-Fi driver into the running kernel: proves it matches the kernel
# (no Wi-Fi chip is needed for the driver to load; it just waits for one)
for m in 8189es 8189fs; do
  out="$(sr "modprobe $m && lsmod | grep -q '^$m ' && echo LOADED; modprobe -r $m")"
  echo "$out" | grep -q LOADED && ok "Wi-Fi driver $m loads into kernel $(r 'uname -r')" || { bad "Wi-Fi driver $m does not load"; echo "$out" | tail -5 | sed 's/^/     /' | tee -a "$REPORT"; }
done
sr "dmesg | grep -iE '8189|module verification|disagrees|Unknown symbol' | tail -n 8" | sed 's/^/  dmesg: /' | tee -a "$REPORT"
for m in brcmfmac rtw88_8723ds rtw88_8821cs rtw88_8822bs ath9k_htc mt7601u rt2800usb rtl8xxxu mt76x2u lima meson_vdec; do
  r "modinfo -F filename $m" | grep -q "\.ko" && say "  ok     module $m" || say "  absent module $m"
done
r 'ls /lib/firmware/meson/vdec/gxl_h264.bin /lib/firmware/brcm/brcmfmac43455-sdio.bin /lib/firmware/rtlwifi/rtl8188eufw.bin 2>&1' | sed 's/^/  /' | tee -a "$REPORT"

say ""; say "---- tuning ----"
r 'cat /sys/block/sda/queue/scheduler; sysctl -n vm.swappiness net.ipv4.tcp_congestion_control; swapon --show --noheadings; cat /proc/sys/net/core/rps_sock_flow_entries' | sed 's/^/  /' | tee -a "$REPORT"
r 'swapon --show --noheadings' | grep -q zram && ok "zram swap active" || bad "zram swap missing"
r 'grep -q "\[bfq\]" /sys/block/sda/queue/scheduler' >/dev/null && ok "BFQ I/O scheduler" || bad "BFQ not selected"
r 'systemctl is-active earlyoom' | grep -q '^active' && ok "earlyoom running" || bad "earlyoom not running"
[ "$EDITION" = cli ] && { r 'sysctl -n net.ipv4.tcp_congestion_control' | grep -q bbr && ok "BBR congestion control" || bad "BBR not active"; }

if [ "$EDITION" = desktop ]; then
  say ""; say "---- desktop ----"
  for i in $(seq 1 40); do r 'pgrep -x xfce4-panel' >/dev/null && break; sleep 10; done
  r 'systemctl is-active lightdm' | grep -q '^active' && ok "LightDM running" || bad "LightDM not running"
  r 'pgrep -x Xorg'         >/dev/null && ok "Xorg running"        || bad "Xorg not running"
  r 'pgrep -u x96 -x xfce4-session' >/dev/null && ok "auto-login into Xfce as x96" || bad "no Xfce session"
  r 'pgrep -x xfce4-panel'  >/dev/null && ok "top bar (xfce4-panel) running" || bad "xfce4-panel not running"
  r 'pgrep -x plank || pgrep -f docklike' >/dev/null && ok "dock running" || bad "dock not running"
  r 'pgrep -x xfdesktop'    >/dev/null && ok "desktop/wallpaper (xfdesktop) running" || bad "xfdesktop not running"
  sleep 45   # let the welcome notification and wallpaper settle before the screenshot
fi

say ""; say "---- memory at idle (2 GB box) ----"
r 'free -m' | tee -a "$REPORT"
used="$(r "free -m | awk '/^Mem:/{print \$3}'")"
say "RAM used at idle: ${used} MiB"
r 'ps -eo rss,comm --sort=-rss | head -12' | tee -a "$REPORT"
say ""; say "---- boot time (emulated CPU) ----"
r 'systemd-analyze; systemd-analyze blame --no-pager | head -10' | tee -a "$REPORT"
[ "$EDITION" = cli ] && { say ""; say "---- greeting ----"; r 'X96OS_COLOR=0 LANG=C.UTF-8 /usr/local/bin/x96os-info' | tee -a "$REPORT"; }

# screenshot of the virtual HDMI output
mon "screendump $T/screen.ppm"; sleep 3
if [ -s "$T/screen.ppm" ]; then
  python3 -c "from PIL import Image; Image.open('$T/screen.ppm').save('$LOGS/screen-$EDITION.png', optimize=True)" \
    && ok "screenshot saved (screen-$EDITION.png)"
fi

r "echo '$PW' | sudo -S -p '' poweroff" >/dev/null 2>&1
say ""; say "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
