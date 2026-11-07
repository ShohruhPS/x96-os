#!/bin/bash
# Runs INSIDE the X96 Mini Armbian image (arm64 chroot) and turns it into X96 OS.
set -Eeuo pipefail
trap 'echo "::error::customize-chroot.sh failed at line $LINENO: $BASH_COMMAND"' ERR

export DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
VERSION="${X96OS_VERSION:-1.0}"
USERNAME="x96"
PASSWORD="x96os"
TZ_NAME="Asia/Tashkent"
OVERLAY=/tmp/x96os/overlay
KVER="$(ls -1 /lib/modules | sort -V | tail -n1)"
APT=(apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

step() { echo; echo "---------- $* ----------"; }
# print only the packages from the arguments that exist in the archive
want() { local p; for p in "$@"; do if apt-cache show "$p" >/dev/null 2>&1; then echo "$p"; else echo "  (not available, skipped: $p)" >&2; fi; done; }
have() { apt-cache show "$1" >/dev/null 2>&1; }

step "Base system"
cat /etc/os-release
echo "kernel: $KVER"
cat /etc/ophub-release 2>/dev/null || true
CODENAME="$(. /etc/os-release; echo "${VERSION_CODENAME:-trixie}")"
BASE_PRETTY="$(. /etc/os-release; echo "${PRETTY_NAME:-Debian}")"

# initramfs must NOT be regenerated in the chroot: ophub's uInitrd is known-good.
if [ -f /etc/initramfs-tools/update-initramfs.conf ]; then
  cp /etc/initramfs-tools/update-initramfs.conf /tmp/x96os/update-initramfs.conf.bak
  sed -i 's/^update_initramfs=.*/update_initramfs=no/' /etc/initramfs-tools/update-initramfs.conf
fi

step "APT sources (enable contrib, non-free, non-free-firmware)"
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
  [ -f "$f" ] || continue
  grep -qE 'debian\.org|/debian' "$f" || continue
  sed -i -E '/^deb(-src)? .*(debian\.org|\/debian)/ { s/ (contrib|non-free-firmware|non-free)//g; s/ main( |$)/ main contrib non-free non-free-firmware\1/ }' "$f"
done
for f in /etc/apt/sources.list.d/*.sources; do
  [ -f "$f" ] || continue
  grep -qE 'URIs:.*(debian\.org|/debian)' "$f" || continue
  sed -i -E 's/^Components:.*/Components: main contrib non-free non-free-firmware/' "$f"
done
grep -rhE '^(deb |URIs|Suites|Components)' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || true

# Keep ophub's kernel / bootloader: never let apt replace them.
for p in $(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -E '^(linux-(image|dtb|u-boot|headers)-|armbian-bsp)' || true); do
  apt-mark hold "$p" || true
done

"${APT[@]}" update

step "Install desktop, apps and tools"
CORE=(
  # display + GPU (Lima / Mali-450 via Mesa)
  xserver-xorg-core xserver-xorg-input-libinput x11-xserver-utils x11-utils xauth dbus-x11
  libgl1-mesa-dri libegl-mesa0 mesa-utils
  # login screen
  lightdm lightdm-gtk-greeter
  # Xfce, trimmed down
  xfce4-session xfwm4 xfce4-panel xfdesktop4 xfce4-settings xfconf xfce4-terminal xfce4-notifyd
  xfce4-appfinder xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-screenshooter
  xfce4-taskmanager xfce4-power-manager
  thunar thunar-volman thunar-archive-plugin xarchiver gvfs udisks2 tumbler
  mousepad ristretto
  # network, sound, bluetooth
  network-manager network-manager-gnome
  pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol alsa-utils
  bluez blueman
  # look & feel
  fonts-inter fonts-dejavu-core fonts-liberation2 fonts-noto-color-emoji
  adwaita-icon-theme hicolor-icon-theme dconf-cli dconf-gsettings-backend
  gsettings-desktop-schemas
  # apps
  firefox-esr
  libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3
  mpv celluloid
  # system
  xdg-user-dirs xdg-utils desktop-file-utils shared-mime-info
  earlyoom cloud-guest-utils locales tzdata sudo htop curl ca-certificates make bc
  python3 libnotify-bin
)
mapfile -t CORE_OK < <(want "${CORE[@]}")
"${APT[@]}" install --no-install-recommends "${CORE_OK[@]}"
# the desktop is useless without these, so stop the build if any is missing
for b in /usr/bin/Xorg /usr/sbin/lightdm /usr/bin/xfwm4 /usr/bin/xfce4-panel /usr/bin/xfce4-session /usr/bin/thunar \
         /usr/bin/firefox-esr /usr/bin/NetworkManager /usr/sbin/NetworkManager /usr/bin/mpv; do
  case "$b" in */NetworkManager) continue ;; esac
  [ -x "$b" ] || { echo "::error::required program missing after install: $b"; exit 1; }
done
[ -x /usr/sbin/NetworkManager ] || [ -x /usr/bin/NetworkManager ] || { echo "::error::NetworkManager missing"; exit 1; }

OPTIONAL=(
  plank xfce4-docklike-plugin webext-ublock-origin-firefox libreoffice-style-colibre
  galculator atril fastfetch xserver-xorg-video-fbdev gnome-disk-utility gtk2-engines-pixbuf
  ffmpeg
)
mapfile -t OPT < <(want "${OPTIONAL[@]}")
[ "${#OPT[@]}" -gt 0 ] && "${APT[@]}" install --no-install-recommends "${OPT[@]}"

# one polkit agent (needed for mounting disks, network settings, etc.)
for agent in xfce-polkit lxpolkit mate-polkit; do
  if have "$agent"; then "${APT[@]}" install --no-install-recommends "$agent"; break; fi
done

step "Firmware for USB Wi-Fi / Bluetooth dongles"
# ophub ships its own board firmware in /lib/firmware; let Debian packages overwrite
# unowned duplicates instead of failing.
mapfile -t FW < <(want firmware-realtek firmware-atheros firmware-mediatek firmware-misc-nonfree firmware-libertas)
[ "${#FW[@]}" -gt 0 ] && "${APT[@]}" -o Dpkg::Options::=--force-overwrite install --no-install-recommends "${FW[@]}"

step "zram compressed swap"
if [ -f /lib/systemd/system/armbian-zram-config.service ] || [ -f /usr/lib/systemd/system/armbian-zram-config.service ]; then
  f=/etc/default/armbian-zram-config
  touch "$f"
  for kv in "ENABLED=true" "ZRAM_PERCENTAGE=75" "SWAP_ALGORITHM=zstd" "MEM_LIMIT_PERCENTAGE=75"; do
    k="${kv%%=*}"
    if grep -qE "^#?\s*$k=" "$f"; then sed -i -E "s|^#?\s*$k=.*|$kv|" "$f"; else echo "$kv" >> "$f"; fi
  done
  echo "using armbian-zram-config"
else
  "${APT[@]}" install --no-install-recommends zram-tools
  printf 'ALGO=zstd\nPERCENT=75\nPRIORITY=100\n' > /etc/default/zramswap
  systemctl enable zramswap.service || true
  echo "using zram-tools"
fi

step "yt-dlp (lets the media player stream YouTube with hardware decoding)"
if curl -fsSL --retry 3 -o /usr/local/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64; then
  chmod 755 /usr/local/bin/yt-dlp
  /usr/local/bin/yt-dlp --version || true
else
  echo "yt-dlp download failed, trying the Debian package"
  have yt-dlp && "${APT[@]}" install --no-install-recommends yt-dlp || true
fi

step "Built-in Wi-Fi drivers for X96 Mini variants (RTL8189ES / RTL8189FTV)"
build_wifi_drivers() {
  local tc_url="https://github.com/ophub/kernel/releases/download/toolchain/arm-gnu-toolchain-15.3.rel1-aarch64-aarch64-none-linux-gnu.tar.xz"
  local tcdir=/tmp/x96os/toolchain src=/tmp/x96os/wifi kbuild="/lib/modules/$KVER/build"
  [ -e "$kbuild/Makefile" ] || { echo "no kernel headers at $kbuild, skipping"; return 0; }
  mkdir -p "$tcdir" "$src"
  curl -fsSL --retry 3 "$tc_url" | tar -xJ -C "$tcdir"
  local cross; cross="$(ls -d "$tcdir"/*/bin | head -n1)/aarch64-none-linux-gnu-"
  local dest="/lib/modules/$KVER/kernel/drivers/net/wireless/x96os"
  mkdir -p "$dest"
  for spec in "8189es:master" "8189fs:rtl8189fs"; do
    local mod="${spec%%:*}" branch="${spec#*:}"
    if modinfo -k "$KVER" "$mod" >/dev/null 2>&1; then echo "$mod already in kernel"; continue; fi
    rm -rf "$src/$mod"; mkdir -p "$src/$mod"
    curl -fsSL --retry 3 "https://github.com/jwrdegoede/rtl8189ES_linux/archive/refs/heads/$branch.tar.gz" \
      | tar -xz -C "$src/$mod" --strip-components=1
    if make -C "$src/$mod" -j"$(nproc)" ARCH=arm64 CROSS_COMPILE="$cross" CC="${cross}gcc" LD="${cross}ld.bfd" \
         KSRC="$kbuild" KVER="$KVER" M="$src/$mod" modules > "$src/$mod.log" 2>&1; then
      install -m644 "$src/$mod/$mod.ko" "$dest/" && echo "built $mod.ko"
    else
      echo "WARNING: $mod did not build (last lines):"; tail -25 "$src/$mod.log"
    fi
  done
  depmod -a "$KVER" || true
  rm -rf "$tcdir" "$src"
}
build_wifi_drivers || echo "WARNING: Wi-Fi driver build skipped"

step "Apply X96 OS configuration overlay"
cp -a "$OVERLAY"/. /
chmod 755 /usr/local/bin/x96os-* /usr/local/sbin/x96os-* 2>/dev/null || true
chmod 755 /etc/update-motd.d/05-x96os 2>/dev/null || true

step "Branding"
echo "x96os" > /etc/hostname
sed -i -E 's/^(127\.0\.1\.1\s+).*/\1x96os/' /etc/hosts
grep -q '127.0.1.1' /etc/hosts || echo "127.0.1.1 x96os" >> /etc/hosts
DEB_VER="$(cat /etc/debian_version 2>/dev/null || echo 13)"
sed -i -E "s|^PRETTY_NAME=.*|PRETTY_NAME=\"X96 OS ${VERSION} (Debian ${DEB_VER})\"|" /etc/os-release
cat > /etc/x96os-release <<EOF
X96OS_VERSION=${VERSION}
X96OS_BUILD_DATE=$(date -u +%Y-%m-%d)
X96OS_DEVICE="X96 Mini (Amlogic S905W)"
X96OS_KERNEL=${KVER}
EOF
echo "X96 OS ${VERSION} \\n \\l" > /etc/issue
echo "X96 OS ${VERSION}" > /etc/issue.net
for f in /etc/update-motd.d/10-armbian-header /etc/update-motd.d/35-armbian-tips /etc/update-motd.d/41-armbian-config; do
  [ -f "$f" ] && chmod -x "$f"
done

step "Locale and time zone"
sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/default/locale
ln -sf "/usr/share/zoneinfo/$TZ_NAME" /etc/localtime
echo "$TZ_NAME" > /etc/timezone

step "User account"
if ! id "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash -c "X96 OS" "$USERNAME"
fi
getent group autologin >/dev/null || groupadd -r autologin
for g in sudo audio video render input plugdev netdev bluetooth lpadmin users autologin; do
  if getent group "$g" >/dev/null; then usermod -aG "$g" "$USERNAME"; fi
done
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd
rm -f /root/.not_logged_in_yet          # skip Armbian's console first-login wizard
for d in Desktop Documents Downloads Music Pictures Videos; do install -d -o "$USERNAME" -g "$USERNAME" "/home/$USERNAME/$d"; done

step "Desktop defaults"
# dock / panel layout depends on what the archive had
PANEL_XML=/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
desktop_file() { ls /usr/share/applications/$1 2>/dev/null | head -n1 || true; }
APPS=(
  "$(desktop_file thunar.desktop)"
  "$(desktop_file firefox-esr.desktop)"
  "$(desktop_file x96os-youtube.desktop)"
  "$(desktop_file '*elluloid*.desktop')"
  "$(desktop_file libreoffice-writer.desktop)"
  "$(desktop_file libreoffice-calc.desktop)"
  "$(desktop_file libreoffice-impress.desktop)"
  "$(desktop_file xfce4-terminal.desktop)"
  "$(desktop_file xfce-settings-manager.desktop)"
)
if dpkg -s plank >/dev/null 2>&1; then
  DOCK=plank
  L=/etc/skel/.config/plank/dock1/launchers
  mkdir -p "$L"
  items=""
  for a in "${APPS[@]}"; do
    [ -n "$a" ] || continue
    n="$(basename "$a" .desktop).dockitem"
    printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$a" > "$L/$n"
    items="$items'$n', "
  done
  printf '[PlankDockItemPreferences]\nLauncher=docklet://trash\n' > "$L/trash.dockitem"
  items="${items}'trash.dockitem'"
  sed -i "s|^dock-items=.*|dock-items=[${items}]|" /etc/dconf/db/local.d/00-x96os
  [ -d /usr/share/plank/themes/WhiteSur-Dark ] || sed -i "s|^theme=.*|theme='Transparent'|" /etc/dconf/db/local.d/00-x96os
else
  DOCK=panel
  rm -f /etc/xdg/autostart/x96os-plank.desktop
  sed -i '/^\[net\/launchpad\/plank/,$d' /etc/dconf/db/local.d/00-x96os
fi
echo "dock: $DOCK"

# top bar (+ bottom dock panel when Plank is not available)
{
cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
EOF
[ "$DOCK" = panel ] && echo '    <value type="int" value="2"/>'
cat <<'EOF'
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="28"/>
      <property name="icon-size" type="uint" value="16"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
EOF
if [ "$DOCK" = panel ]; then
cat <<'EOF'
    <property name="panel-2" type="empty">
      <property name="position" type="string" value="p=10;x=0;y=0"/>
      <property name="length" type="uint" value="1"/>
      <property name="length-adjust" type="bool" value="true"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="56"/>
      <property name="icon-size" type="uint" value="44"/>
      <property name="autohide-behavior" type="uint" value="1"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="20"/>
      </property>
    </property>
EOF
fi
cat <<'EOF'
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu">
      <property name="button-icon" type="string" value="/usr/share/pixmaps/x96os-start.png"/>
      <property name="show-button-title" type="bool" value="false"/>
      <property name="show-button-icon" type="bool" value="true"/>
    </property>
    <property name="plugin-2" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-3" type="string" value="systray">
      <property name="square-icons" type="bool" value="true"/>
    </property>
    <property name="plugin-4" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
    </property>
    <property name="plugin-5" type="string" value="clock">
      <property name="mode" type="uint" value="2"/>
      <property name="digital-layout" type="uint" value="3"/>
      <property name="digital-time-format" type="string" value="%a %e %b  %H:%M"/>
    </property>
    <property name="plugin-6" type="string" value="actions"/>
EOF
[ "$DOCK" = panel ] && echo '    <property name="plugin-20" type="string" value="docklike"/>'
cat <<'EOF'
  </property>
</channel>
EOF
} > "$PANEL_XML"

if [ "$DOCK" = panel ]; then
  pinned=""
  for a in "${APPS[@]}"; do [ -n "$a" ] && pinned="${pinned}${a};"; done
  mkdir -p /etc/skel/.config/xfce4/panel
  printf '[user]\npinned=%s\n' "$pinned" > /etc/skel/.config/xfce4/panel/docklike-20.rc
fi

# keyboard shortcuts: Super = app menu, Super+Space = search (like Spotlight)
python3 - <<'PY'
import xml.etree.ElementTree as ET, os
p = "/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
if os.path.exists(p):
    t = ET.parse(p); root = t.getroot()
    add = {"Super_L": "xfce4-popup-whiskermenu",
           "<Super>space": "xfce4-appfinder --collapsed",
           "<Super>e": "thunar",
           "<Super>t": "xfce4-terminal",
           "<Primary><Alt>t": "xfce4-terminal"}
    for branch in ("default", "custom"):
        node = root.find(f"./property[@name='commands']/property[@name='{branch}']")
        if node is None: continue
        for k, v in add.items():
            for old in node.findall(f"./property[@name='{k}']"): node.remove(old)
            ET.SubElement(node, "property", {"name": k, "type": "string", "value": v})
    t.write(p, encoding="UTF-8", xml_declaration=True)
    print("shortcuts updated")
PY
# whole home of the existing user gets the skel defaults too
cp -a /etc/skel/. "/home/$USERNAME/"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

step "Firefox tuning"
FFJS=/etc/firefox-esr/firefox-esr.js
if [ -d /etc/firefox-esr ]; then
  touch "$FFJS"
  grep -q 'X96 OS' "$FFJS" || cat /etc/x96os/firefox-prefs.js >> "$FFJS"
fi

step "System settings databases"
dconf update || true
glib-compile-schemas /usr/share/glib-2.0/schemas || true
for t in WhiteSur WhiteSur-dark WhiteSur-light hicolor; do
  [ -d "/usr/share/icons/$t" ] && gtk-update-icon-cache -f -q "/usr/share/icons/$t" 2>/dev/null || true
done
update-desktop-database -q /usr/share/applications || true
fc-cache -f >/dev/null 2>&1 || true

step "Services"
systemctl set-default graphical.target
systemctl enable lightdm.service || true
systemctl enable NetworkManager.service || true
systemctl enable x96os-firstboot.service x96os-tune.service x96os-audio.service
systemctl enable earlyoom.service || true
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
# Ethernet and Wi-Fi are handed to NetworkManager (nm-applet in the top bar)
if [ -d /etc/netplan ]; then
  mkdir -p /etc/netplan/backup
  for f in /etc/netplan/*.yaml; do [ -f "$f" ] && mv "$f" /etc/netplan/backup/; done
  printf 'network:\n  version: 2\n  renderer: NetworkManager\n' > /etc/netplan/01-x96os-networkmanager.yaml
  chmod 600 /etc/netplan/01-x96os-networkmanager.yaml
fi
[ -f /etc/NetworkManager/NetworkManager.conf ] && sed -i 's/^managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf
systemctl disable systemd-networkd.service systemd-networkd.socket 2>/dev/null || true
# trim background work that a TV box does not need
for u in apt-daily.timer apt-daily-upgrade.timer man-db.timer e2scrub_all.timer e2scrub_reap.service \
         NetworkManager-wait-online.service systemd-networkd-wait-online.service ModemManager.service \
         avahi-daemon.service avahi-daemon.socket cups.service cups-browsed.service unattended-upgrades.service \
         armbian-led-state.service; do
  systemctl disable "$u" 2>/dev/null || true
done
systemctl mask NetworkManager-wait-online.service systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask systemd-firstboot.service 2>/dev/null || true   # never stop at a console prompt on first boot
"${APT[@]}" purge unattended-upgrades 2>/dev/null || true

step "Clean up"
"${APT[@]}" autoremove --purge || true
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin /var/cache/debconf/*-old /var/tmp/* /root/.cache
find /var/log -type f -exec truncate -s 0 {} + 2>/dev/null || true
rm -f /root/.bash_history "/home/$USERNAME/.bash_history"
: > /etc/machine-id                       # unique id is generated on first boot
rm -f /var/lib/dbus/machine-id && ln -sf /etc/machine-id /var/lib/dbus/machine-id
rm -f /etc/ssh/ssh_host_*                  # fresh host keys on first boot (armbian-firstrun / ssh)
if [ -f /tmp/x96os/update-initramfs.conf.bak ]; then
  cp /tmp/x96os/update-initramfs.conf.bak /etc/initramfs-tools/update-initramfs.conf
fi

step "Build info"
{
  echo "X96 OS ${VERSION} built $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "Base: $BASE_PRETTY ($CODENAME), kernel $KVER"
  echo "Dock: $DOCK"
  echo "Wi-Fi modules added: $(ls /lib/modules/$KVER/kernel/drivers/net/wireless/x96os 2>/dev/null | xargs || echo none)"
  echo "Themes: $(tr '\n' ' ' < /tmp/x96os/themes.txt)"
  echo "Packages installed: $(dpkg-query -W | wc -l)"
  echo "Root usage: $(du -sh --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run / 2>/dev/null | cut -f1)"
} | tee /etc/x96os-build-info.txt
echo "customize-chroot.sh finished OK"
