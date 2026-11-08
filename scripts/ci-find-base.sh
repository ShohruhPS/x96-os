#!/usr/bin/env bash
# CI: download the newest Armbian <release> arm64 trunk base image from ophub's releases.
set -euo pipefail
: "${DEBIAN_RELEASE:=trixie}"
mkdir -p build/output/images logs
curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/ophub/amlogic-s9xxx-armbian/releases?per_page=60" -o releases.json
jq -r --arg T "Armbian_${DEBIAN_RELEASE}_arm64_" \
  '.[] | select(.tag_name|contains($T)) | .tag_name as $t | .assets[] | select(.name|endswith(".img.gz")) | select(.name|contains("-trunk_")) | "\($t)  \(.name)  \(.updated_at)"' \
  releases.json | head -20 | tee logs/base-candidates.txt
# Prefer a minimal/server trunk image, newest first; never a desktop one (X96 OS adds its own).
pick() {
  jq -r --arg T "Armbian_${DEBIAN_RELEASE}_arm64_" --arg F "$1" \
    '[.[] | select(.tag_name|contains($T)) | .assets[]
      | select(.name|endswith(".img.gz")) | select(.name|contains("-trunk_"))
      | select(.name|test("desktop";"i")|not) | select(.name|test($F;"i"))]
     | sort_by(.updated_at) | reverse | .[0] // empty | "\(.url) \(.name)"' releases.json
}
sel="$(pick minimal)"; [ -n "$sel" ] || sel="$(pick server)"; [ -n "$sel" ] || sel="$(pick .)"
[ -n "$sel" ] || { echo "::error::No Armbian ${DEBIAN_RELEASE} trunk base image found in ophub releases"; exit 1; }
url="${sel%% *}"; name="${sel#* }"
echo "Using base image: ${name}" | tee logs/base-image.txt
curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/octet-stream" "$url" -o "build/output/images/${name}"
ls -lh build/output/images
