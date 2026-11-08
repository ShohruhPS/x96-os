#!/usr/bin/env bash
# CI: publish the built images (out/*.img.xz) as the GitHub release of this X96 OS version.
#
# One release per version: the version comes from the VERSION file (e.g. 1.0, 1.1, 2.0).
#  - First build of a version   -> new release "X96 OS <version>" (tag v<version>).
#  - Later builds of that version -> the same release gets the new images (newest fixes).
#  - New version in VERSION      -> new release; older versions are kept.
# Images that fail to boot in the QEMU boot test are never published.
set -euo pipefail
VERSION="$(tr -d ' \r\n' < VERSION 2>/dev/null || true)"; VERSION="${VERSION:-${X96OS_VERSION:-1.0}}"
cd out
shopt -s nullglob
imgs=(X96OS-*.img.xz)
[ "${#imgs[@]}" -gt 0 ] || { echo "::error::no images to release"; exit 1; }

# never publish an image that does not boot
for rep in ../logs/*/smoketest-*.txt; do
  if grep -qE '^FAIL  (did not reach a login|SSH login failed|QEMU exited|no .* image|QEMU kernel)' "$rep"; then
    echo "::error::boot test failed ($(basename "$rep")): not publishing this build"; grep '^FAIL' "$rep"; exit 1
  fi
done

files=(); editions=()
for img in "${imgs[@]}"; do
  size=$(stat -c %s "$img")
  [ "$size" -lt 2140000000 ] || { echo "::error::$img is larger than GitHub's 2 GB asset limit ($size bytes)"; exit 1; }
  files+=("$img" "$img.sha256")
  case "$img" in *-desktop-*) editions+=(desktop) ;; *-cli-*) editions+=(cli) ;; esac
done
for q in x96os-qemu-vmlinuz x96os-qemu-initrd.img; do [ -f "$q" ] && files+=("$q"); done

tag="v${VERSION}"
REPO="${GITHUB_REPOSITORY}"
{
  echo "## X96 OS ${VERSION} for the X96 Mini (Amlogic S905W)"
  echo
  echo "Build ${GITHUB_RUN_NUMBER}, $(date -u '+%Y-%m-%d'), commit \`${GITHUB_SHA:0:7}\`. Every build is boot-tested on a virtual X96 Mini before it is published."
  echo
  echo "| File | Edition |"
  echo "|---|---|"
  for img in "${imgs[@]}"; do
    case "$img" in
      *-desktop-*) echo "| \`$img\` | **Desktop**: macOS-style desktop, Firefox, LibreOffice, Celluloid |" ;;
      *-cli-*)     echo "| \`$img\` | **CLI**: headless / server, SSH, \`x96os\` helper |" ;;
      *)           echo "| \`$img\` | |" ;;
    esac
  done
  echo
  echo "**You only need one \`.img.xz\`.** Flash it to a microSD card or USB stick (8 GB or larger) with balenaEtcher or Rufus. No renaming or editing needed."
  echo "The \`.sha256\` files are checksums; \`x96os-qemu-*\` are only for running the image on a PC."
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
  cat ../logs/*/base-image.txt </dev/null 2>/dev/null | sort -u || true
  for f in x96os-build-info-*.txt; do echo; cat "$f"; done
  echo '```'
  echo
  echo "### SHA256"
  echo '```'
  cat ./*.sha256
  echo '```'
} > "${RUNNER_TEMP:-/tmp}/notes.md"
NOTES="${RUNNER_TEMP:-/tmp}/notes.md"
TITLE="X96 OS ${VERSION}"

if gh release view "$tag" --repo "$REPO" >/dev/null 2>&1; then
  echo "release $tag exists: updating it with build ${GITHUB_RUN_NUMBER}"
  old="$(gh release view "$tag" --repo "$REPO" --json assets -q '.assets[].name')"
  gh release upload "$tag" "${files[@]}" --repo "$REPO" --clobber
  # drop the previous images of the editions that were just rebuilt (file names carry the date)
  for a in $old; do
    printf '%s\n' "${files[@]}" | grep -qxF "$a" && continue
    for ed in "${editions[@]}"; do
      case "$a" in X96OS-*-"$ed"-*) gh release delete-asset "$tag" "$a" --repo "$REPO" --yes ;; esac
    done
  done
  # point the tag at this build's commit
  gh api -X PATCH "repos/$REPO/git/refs/tags/$tag" -f sha="$GITHUB_SHA" -F force=true >/dev/null || true
  gh release edit "$tag" --repo "$REPO" --title "$TITLE" --notes-file "$NOTES" --latest
else
  gh release create "$tag" "${files[@]}" --repo "$REPO" --target "$GITHUB_SHA" \
    --title "$TITLE" --notes-file "$NOTES" --latest
fi

# Before releases were named by version, every build got its own "v1.0-buildN" release.
# Those test builds are replaced by the version release above, so remove them.
for t in $(gh release list --repo "$REPO" --limit 300 --json tagName -q '.[].tagName' | grep -E '^v[0-9.]+-build[0-9]+$' || true); do
  echo "removing old per-build release $t"
  gh release delete "$t" --repo "$REPO" --yes --cleanup-tag || true
done
