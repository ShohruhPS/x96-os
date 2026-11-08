#!/usr/bin/env bash
# X96 OS image builder (runs on an arm64 Linux host as root).
#
#   sudo scripts/build-image.sh <ophub-x96-mini-image.img[.gz|.xz]> <output-dir>
#
# Takes the ophub Armbian image packaged for the X96 Mini (correct dtb + u-boot.ext
# already in place), customises it in a chroot, shrinks it and compresses it.
set -Eeuo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
IN="$(readlink -f "$1")"
OUTDIR="$2"
VERSION="${X96OS_VERSION:-1.0}"
EDITION="${X96OS_EDITION:-desktop}"     # desktop | cli
WORK="${WORK:-/tmp/x96os-work}"
MNT="$WORK/rootfs"
IMG="$WORK/x96os.img"
LOOP=""

log()  { echo; echo "=================== $* ==================="; }
fail() { echo "::error::$*"; exit 1; }

cleanup() {
  set +e
  for m in run dev/pts dev proc sys boot; do
    mountpoint -q "$MNT/$m" && umount -lf "$MNT/$m"
  done
  mountpoint -q "$MNT" && umount -lf "$MNT"
  [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null
  return 0
}
trap cleanup EXIT
trap 'echo "::error::build-image.sh failed at line $LINENO: $BASH_COMMAND"' ERR

[ "$(id -u)" = 0 ] || fail "run as root"
# ophub writes its packaged image into the same folder as the generic Armbian base image:
# make sure we use the X96 Mini one, never the base.
BOARD_ID="${X96OS_BOARD:-s905w-x96-mini}"
if [[ "$(basename "$IN")" != *"_${BOARD_ID}_"* ]]; then
  ALT="$(ls -1t "$(dirname "$IN")"/*"_${BOARD_ID}_"*.img* 2>/dev/null | grep -E '\.img(\.gz|\.xz)?$' | head -n1 || true)"
  [ -n "$ALT" ] || fail "no ${BOARD_ID} image found next to $(basename "$IN") (ophub output missing?)"
  echo "Input $(basename "$IN") is not the ${BOARD_ID} image, using $(basename "$ALT")"
  IN="$(readlink -f "$ALT")"
fi
[ "$(uname -m)" = aarch64 ] || fail "needs an arm64 host (got $(uname -m))"
case "$EDITION" in desktop|cli) ;; *) fail "X96OS_EDITION must be desktop or cli (got $EDITION)" ;; esac
echo "Building X96 OS ${VERSION} (${EDITION} edition)"
rm -rf "$WORK"; mkdir -p "$WORK" "$MNT" "$OUTDIR"

# ------------------------------------------------------------------ 1. unpack
log "Unpacking $(basename "$IN")"
case "$IN" in
  *.gz) pigz -dc "$IN" > "$IMG" ;;
  *.xz) xz -dc -T0 "$IN" > "$IMG" ;;
  *)    cp "$IN" "$IMG" ;;
esac
ls -lh "$IMG"
parted -s "$IMG" unit MiB print

LOOP="$(losetup --find --show --partscan "$IMG")"
sleep 1
BOOTP="${LOOP}p1"; ROOTP="${LOOP}p2"
[ -b "$ROOTP" ] || fail "rootfs partition not found on $LOOP"
blkid "$BOOTP" "$ROOTP" || true
mount "$ROOTP" "$MNT"
mount "$BOOTP" "$MNT/boot"

log "Boot partition (should already be set up for the X96 Mini)"
ls -la "$MNT/boot"
grep -E '^(FDT|APPEND)' "$MNT/boot/uEnv.txt" || true
# Older ophub kernels need u-boot.ext to chain-load; kernels with the TEXT_OFFSET patch (header
# word 0108) boot straight from the stock Android bootloader, so ophub leaves u-boot.ext out.
if [ -f "$MNT/boot/u-boot.ext" ]; then
  echo "u-boot.ext present"
else
  OFF="$(hexdump -n 15 -x "$MNT/boot/zImage" 2>/dev/null | head -n1 | awk '{print $7}' || true)"
  [ "$OFF" = "0108" ] || fail "u-boot.ext missing and the kernel (header $OFF) needs it"
  echo "kernel has the TEXT_OFFSET patch: boots directly, no u-boot.ext needed"
fi
grep -q 'meson-gxl-s905w-x96-mini.dtb' "$MNT/boot/uEnv.txt" || fail "uEnv.txt does not point to the X96 Mini dtb"
# The real box boots: stock Android u-boot -> aml_autoscript / s905_autoscript -> uEnv.txt -> kernel.
for f in aml_autoscript s905_autoscript boot.scr emmc_autoscript zImage uInitrd uEnv.txt; do
  [ -s "$MNT/boot/$f" ] || fail "boot file missing or empty: $f"
done
FDTPATH="$(awk -F= '/^FDT=/{print $2}' "$MNT/boot/uEnv.txt")"
[ -s "$MNT/boot$FDTPATH" ] || fail "device tree $FDTPATH not found on the boot partition"
RUUID="$(blkid -s UUID -o value "$ROOTP")"
grep -q "root=UUID=$RUUID" "$MNT/boot/uEnv.txt" || fail "uEnv.txt root UUID does not match the rootfs ($RUUID)"
echo "boot chain OK: autoscripts present, $FDTPATH present, root=UUID=$RUUID matches"
# Kernel + initrd for running the image in QEMU (scripts/run-qemu.sh / .ps1): the ophub kernel has
# virtio and USB-storage support, so the same kernel boots the "virtual X96 Mini".
KIMG="$(ls -1 "$MNT"/boot/vmlinuz-* 2>/dev/null | head -n1 || true)"
KINI="$(ls -1 "$MNT"/boot/initrd.img-* 2>/dev/null | head -n1 || true)"
if [ -n "$KIMG" ] && [ -n "$KINI" ]; then
  cp "$KIMG" "$OUTDIR/x96os-qemu-vmlinuz"; cp "$KINI" "$OUTDIR/x96os-qemu-initrd.img"
  echo "exported $(basename "$KIMG") + $(basename "$KINI") for QEMU testing"
else
  echo "WARNING: kernel/initrd not found in /boot, QEMU test files not exported"
fi
cat "$MNT/etc/ophub-release" 2>/dev/null || true

# ------------------------------------------------------------------ 2. artwork + themes (host side, arch independent)
: > "$WORK/themes.txt"
if [ "$EDITION" = desktop ]; then
log "Generating X96 OS artwork"
ART="$WORK/art"
python3 "$REPO/assets/make-wallpapers.py" "$ART"
install -d "$MNT/usr/share/backgrounds/x96os" "$MNT/usr/share/pixmaps"
cp "$ART"/x96os-{dusk,dawn,ocean,ember,login}.jpg "$MNT/usr/share/backgrounds/x96os/"
cp "$ART/x96os-logo-256.png" "$MNT/usr/share/pixmaps/x96os-logo.png"
cp "$ART/x96os-symbolic-48.png" "$MNT/usr/share/pixmaps/x96os-start.png"
for s in 16 22 24 32 48 64 128 256 512; do
  install -D -m644 "$ART/x96os-logo-$s.png" "$MNT/usr/share/icons/hicolor/${s}x${s}/apps/x96os.png"
done

log "Installing WhiteSur themes (macOS look)"
TH="$WORK/themes"; mkdir -p "$TH"
for r in WhiteSur-gtk-theme WhiteSur-icon-theme WhiteSur-cursors; do
  for try in 1 2 3 4; do
    git clone -q --depth 1 "https://github.com/vinceliuice/$r" "$TH/$r" && break
    rm -rf "$TH/$r"; [ "$try" = 4 ] && fail "could not download $r"; sleep 20
  done
  echo "$r $(git -C "$TH/$r" rev-parse --short HEAD)" >> "$WORK/themes.txt"
done
install -d "$MNT/usr/share/themes" "$MNT/usr/share/icons" "$MNT/usr/share/plank/themes"
# "solid" variants: no translucency, much cheaper to draw on the Mali-450.
for v in Dark-solid Light-solid; do
  tar -xf "$TH/WhiteSur-gtk-theme/release/WhiteSur-$v.tar.xz" -C "$MNT/usr/share/themes"
done
ls "$MNT/usr/share/themes"
[ -d "$MNT/usr/share/themes/WhiteSur-Dark-solid/xfwm4" ] || fail "WhiteSur-Dark-solid theme incomplete"
for v in Dark Light; do
  if [ -f "$TH/WhiteSur-gtk-theme/other/plank/theme-$v/dock.theme" ]; then
    install -D -m644 "$TH/WhiteSur-gtk-theme/other/plank/theme-$v/dock.theme" "$MNT/usr/share/plank/themes/WhiteSur-$v/dock.theme"
  fi
done
( cd "$TH/WhiteSur-icon-theme" && bash ./install.sh -d "$MNT/usr/share/icons" )
cp -r "$TH/WhiteSur-cursors/dist" "$MNT/usr/share/icons/WhiteSur-cursors"
ls "$MNT/usr/share/icons"
fi

# ------------------------------------------------------------------ 3. chroot customisation
log "Preparing chroot"
for m in dev dev/pts proc sys; do mount --bind "/$m" "$MNT/$m"; done
mount -t tmpfs tmpfs "$MNT/run"   # clean /run so package scripts do not see the host systemd
RESOLV_BAK=""
if [ -e "$MNT/etc/resolv.conf" ] || [ -L "$MNT/etc/resolv.conf" ]; then
  RESOLV_BAK="$WORK/resolv.conf.orig"; cp -a "$MNT/etc/resolv.conf" "$RESOLV_BAK"; rm -f "$MNT/etc/resolv.conf"
fi
{ cat /run/systemd/resolve/resolv.conf 2>/dev/null || cat /etc/resolv.conf; } > "$MNT/etc/resolv.conf"
printf '#!/bin/sh\nexit 101\n' > "$MNT/usr/sbin/policy-rc.d"; chmod +x "$MNT/usr/sbin/policy-rc.d"

rm -rf "$MNT/tmp/x96os"; mkdir -p "$MNT/tmp/x96os"
cp -a "$REPO/overlay" "$REPO/overlay-common" "$REPO/overlay-cli" "$MNT/tmp/x96os/"
cp "$REPO/scripts/customize-chroot.sh" "$MNT/tmp/x96os/"
cp "$WORK/themes.txt" "$MNT/tmp/x96os/"

log "Running customize-chroot.sh"
chroot "$MNT" /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  X96OS_VERSION="$VERSION" X96OS_EDITION="$EDITION" /bin/bash /tmp/x96os/customize-chroot.sh

log "Leaving chroot"
cp "$MNT/etc/x96os-build-info.txt" "$OUTDIR/x96os-build-info-${EDITION}.txt" 2>/dev/null || true
rm -f "$MNT/usr/sbin/policy-rc.d"
rm -f "$MNT/etc/resolv.conf"
if [ -n "$RESOLV_BAK" ]; then cp -a "$RESOLV_BAK" "$MNT/etc/resolv.conf"; else ln -s /run/NetworkManager/resolv.conf "$MNT/etc/resolv.conf"; fi
rm -rf "$MNT/tmp/x96os" "$MNT/tmp/"* 2>/dev/null || true
# stop anything a package script left running inside the chroot, or the unmount fails
for p in /proc/[0-9]*; do
  [ "$(readlink "$p/root" 2>/dev/null)" = "$MNT" ] && kill -9 "${p#/proc/}" 2>/dev/null || true
done
sleep 1
for m in run dev/pts dev proc sys; do umount -lf "$MNT/$m"; done
df -h "$MNT" "$MNT/boot"
sync
umount "$MNT/boot"
umount "$MNT"

# ------------------------------------------------------------------ 4. shrink (first boot grows it back to the card size)
log "Shrinking rootfs"
e2fsck -fy "$ROOTP" || [ $? -le 1 ] || fail "e2fsck failed"
MIN_BLOCKS=$(resize2fs -P "$ROOTP" 2>/dev/null | awk -F': ' '/minimum/{print $2}')
BS=$(dumpe2fs -h "$ROOTP" 2>/dev/null | awk -F': *' '/^Block size/{print $2}')
[ -n "$MIN_BLOCKS" ] && [ -n "$BS" ] || fail "could not read filesystem size"
TARGET_BLOCKS=$(( MIN_BLOCKS + (600 * 1024 * 1024 / BS) ))   # +600 MiB head-room
CUR_BLOCKS=$(dumpe2fs -h "$ROOTP" 2>/dev/null | awk -F': *' '/^Block count/{print $2}')
echo "blocks: current=$CUR_BLOCKS minimum=$MIN_BLOCKS target=$TARGET_BLOCKS (block size $BS)"
if [ "$TARGET_BLOCKS" -lt "$CUR_BLOCKS" ]; then
  resize2fs "$ROOTP" "$TARGET_BLOCKS"
  START=$(partx -g -o START -n 2 "$LOOP")
  SECTORS=$(( TARGET_BLOCKS * BS / 512 ))
  losetup -d "$LOOP"; LOOP=""
  echo "${START},${SECTORS}" | sfdisk -N 2 --no-reread --no-tell-kernel "$IMG"
  truncate -s $(( (START + SECTORS) * 512 + 1024 * 1024 )) "$IMG"
  LOOP="$(losetup --find --show --partscan "$IMG")"; sleep 1
  e2fsck -fy "${LOOP}p2" || [ $? -le 1 ] || fail "e2fsck after shrink failed"
fi
parted -s "$IMG" unit MiB print
losetup -d "$LOOP"; LOOP=""

# ------------------------------------------------------------------ 5. compress
log "Compressing"
NAME="X96OS-${VERSION}-${EDITION}-x96mini-s905w-$(date -u +%Y%m%d).img"
mv "$IMG" "$OUTDIR/$NAME"
xz -T0 -6 -v "$OUTDIR/$NAME"
( cd "$OUTDIR" && sha256sum "$NAME.xz" > "$NAME.xz.sha256" )
# hand the results back to the user who ran sudo (the release step runs unprivileged)
[ -n "${SUDO_UID:-}" ] && chown -R "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$OUTDIR"
ls -lh "$OUTDIR"
log "Done: $OUTDIR/$NAME.xz"
