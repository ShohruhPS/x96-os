#!/usr/bin/env bash
# CI: turn the ophub X96 Mini image into X96 OS (<edition> = desktop | cli).
set -o pipefail
EDITION="${1:?edition}"
mkdir -p logs
echo "ophub output: ${PACKAGED_OUTPUTPATH:-?} (${PACKAGED_STATUS:-?})"
ls -lh "${PACKAGED_OUTPUTPATH}" || true
[ "${PACKAGED_STATUS:-}" = "success" ] || { echo "::error::ophub packaging failed"; exit 1; }
src="$(ls -1 "${PACKAGED_OUTPUTPATH}"/*.img.gz "${PACKAGED_OUTPUTPATH}"/*.img.xz "${PACKAGED_OUTPUTPATH}"/*.img 2>/dev/null | head -n1 || true)"
[ -n "$src" ] || { echo "::error::no image in ophub output"; exit 1; }
sudo env X96OS_VERSION="${X96OS_VERSION:-1.0}" X96OS_EDITION="$EDITION" \
  bash scripts/build-image.sh "$src" "${GITHUB_WORKSPACE}/out" 2>&1 | tee "logs/build-image-${EDITION}.log"
rc=$?
[ "$rc" -eq 0 ] || exit "$rc"

# Boot the new image in QEMU and check it before it gets published.
# X96OS_SMOKE_STRICT=1 makes a failed boot test block the release.
if [ -f scripts/ci-smoketest.sh ]; then
  if bash scripts/ci-smoketest.sh "$EDITION" "${GITHUB_WORKSPACE}/out"; then
    echo "smoke test passed"
  else
    echo "::warning::boot test (QEMU) failed for the $EDITION image, see logs/smoketest-$EDITION.txt"
    [ "${X96OS_SMOKE_STRICT:-0}" = 1 ] && exit 1
  fi
fi
exit 0
