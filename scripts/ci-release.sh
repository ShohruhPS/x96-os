#!/usr/bin/env bash
# CI: publish every built image (out/*.img.xz) as one GitHub release.
set -euo pipefail
cd out
shopt -s nullglob
imgs=(X96OS-*.img.xz)
[ "${#imgs[@]}" -gt 0 ] || { echo "::error::no images to release"; exit 1; }
files=()
for img in "${imgs[@]}"; do
  size=$(stat -c %s "$img")
  [ "$size" -lt 2140000000 ] || { echo "::error::$img is larger than GitHub's 2 GB asset limit ($size bytes)"; exit 1; }
  files+=("$img" "$img.sha256")
done
for q in x96os-qemu-vmlinuz x96os-qemu-initrd.img; do [ -f "$q" ] && files+=("$q"); done
tag="v${X96OS_VERSION}-build${GITHUB_RUN_NUMBER}"
{
  echo "## X96 OS ${X96OS_VERSION} for the X96 Mini (Amlogic S905W)"
  echo
  echo "| File | Edition |"
  echo "|---|---|"
  for img in "${imgs[@]}"; do
    case "$img" in
      *-desktop-*) echo "| \`$img\` | **Desktop**: macOS-style desktop, Firefox, LibreOffice, Celluloid |" ;;
      *-cli-*)     echo "| \`$img\` | **CLI**: headless / server, SSH, \`x96os\` helper, ~300 MB RAM at idle |" ;;
      *)           echo "| \`$img\` | |" ;;
    esac
  done
  echo
  echo "Flash the \`.img.xz\` to a microSD card or USB stick (8 GB or larger) with balenaEtcher or Rufus. No renaming or editing needed."
  echo
  echo "- Login: user \`x96\`, default password in the README. The desktop logs in automatically."
  echo "- First boot from the card: hold the reset button inside the AV jack with a toothpick while plugging in power, release after ~5 s."
  echo "- Install to internal storage (erases Android): \`x96os install\`, then pick **113 X96-Mini**."
  echo "- **No box at hand?** Download \`x96os-qemu-vmlinuz\` + \`x96os-qemu-initrd.img\` too and run the image in QEMU: see [docs/TESTING.md](../../blob/main/docs/TESTING.md)."
  echo "- Found a bug? Run \`x96os report\` and attach the file to an [issue](../../issues)."
  echo "- Source code of the bundled open-source software: see [THIRD-PARTY.md](../../blob/main/THIRD-PARTY.md)."
  echo
  echo "### Build details"
  echo '```'
  cat ../logs/*/base-image.txt 2>/dev/null | sort -u || true
  for f in x96os-build-info-*.txt; do echo; cat "$f"; done
  echo '```'
  echo
  echo "### SHA256"
  echo '```'
  cat ./*.sha256
  echo '```'
} > "${RUNNER_TEMP:-/tmp}/notes.md"
gh release create "$tag" "${files[@]}" --repo "${GITHUB_REPOSITORY}" \
  --title "X96 OS ${X96OS_VERSION} (build ${GITHUB_RUN_NUMBER})" --notes-file "${RUNNER_TEMP:-/tmp}/notes.md" --latest
