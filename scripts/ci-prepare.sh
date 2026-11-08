#!/usr/bin/env bash
# CI: install the build tools on the GitHub arm64 runner.
set -x
mkdir -p logs
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc 2>/dev/null || true
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -y update
sudo -E apt-get -y install $(curl -fsSL https://ophub.org/ubuntu2604-build-armbian-depends) || true
sudo -E apt-get -y install jq xz-utils pigz parted fdisk e2fsprogs dosfstools rsync git curl bsdextrautils \
     python3-numpy python3-pil fonts-inter gtk-update-icon-cache \
     qemu-system-arm qemu-utils socat sshpass
df -h /
