#!/usr/bin/env bash
# Run an X96 OS image in QEMU as a "virtual X96 Mini": 4x Cortex-A53, 2 GB RAM,
# the image attached as a USB stick (exactly how the real box boots it).
#
#   scripts/run-qemu.sh X96OS-1.0-cli-x96mini-s905w-YYYYMMDD.img.xz
#
# Needs: qemu-system-aarch64 (+ qemu-img), xz. Put x96os-qemu-vmlinuz and
# x96os-qemu-initrd.img (from the same release) next to the image.
#   Linux:  sudo apt install qemu-system-arm qemu-utils xz-utils
#   macOS:  brew install qemu xz
set -euo pipefail

IMG="${1:?usage: run-qemu.sh <X96OS-*.img or .img.xz> [disk size, default 16G]}"
SIZE="${2:-16G}"
DIR="$(cd "$(dirname "$IMG")" && pwd)"
KERNEL="${KERNEL:-$DIR/x96os-qemu-vmlinuz}"
INITRD="${INITRD:-$DIR/x96os-qemu-initrd.img}"

[ -f "$KERNEL" ] || { echo "missing $KERNEL (download x96os-qemu-vmlinuz from the release)"; exit 1; }
[ -f "$INITRD" ] || { echo "missing $INITRD (download x96os-qemu-initrd.img from the release)"; exit 1; }

case "$IMG" in
  *.xz) RAW="${IMG%.xz}"
        if [ ! -f "$RAW" ]; then echo "Unpacking $IMG ..."; xz -dk -T0 "$IMG"; fi
        IMG="$RAW" ;;
esac
# room to grow: X96 OS expands its root partition to fill the disk on first boot
qemu-img resize -f raw "$IMG" "$SIZE" >/dev/null

# Hardware acceleration only works on an ARM64 host; elsewhere QEMU emulates the CPU (slower).
ACCEL=(-accel tcg,thread=multi -cpu cortex-a53)
case "$(uname -s)-$(uname -m)" in
  Linux-aarch64) [ -w /dev/kvm ] && ACCEL=(-accel kvm -cpu host) ;;
  Darwin-arm64)  ACCEL=(-accel hvf -cpu host) ;;
esac
echo "CPU mode: ${ACCEL[*]}"
echo "SSH into the VM later with:  ssh -p 2222 x96@localhost"

exec qemu-system-aarch64 -M virt "${ACCEL[@]}" -smp 4 -m 2048 \
  -kernel "$KERNEL" -initrd "$INITRD" \
  -append "root=LABEL=ROOTFS rootwait rw console=ttyAMA0 console=tty0 net.ifnames=0 fsck.repair=yes" \
  -device qemu-xhci,id=xhci \
  -drive if=none,id=x96disk,file="$IMG",format=raw \
  -device usb-storage,bus=xhci.0,drive=x96disk \
  -device usb-kbd,bus=xhci.0 -device usb-tablet,bus=xhci.0 \
  -device virtio-gpu-pci,xres=1920,yres=1080 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0 \
  -serial mon:stdio
