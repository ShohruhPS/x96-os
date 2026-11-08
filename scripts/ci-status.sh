#!/usr/bin/env bash
# CI: write a build report to the 'build-status' branch (readable without Actions access).
set +e
BUILD_RESULT="$1"; RELEASE_RESULT="$2"
d="$(mktemp -d)"
{
  echo "# X96 OS build status"
  echo
  echo "- run: ${GITHUB_RUN_NUMBER} (id ${GITHUB_RUN_ID}), commit ${GITHUB_SHA}"
  echo "- finished: $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "- build jobs: ${BUILD_RESULT}"
  echo "- release: ${RELEASE_RESULT}"
  for dir in logs/logs-*; do
    [ -d "$dir" ] || continue
    ed="${dir##*/logs-}"
    echo
    echo "## ${ed}"
    [ -f "$dir/outcome.txt" ] && { echo '```'; cat "$dir/outcome.txt"; echo '```'; }
    [ -f "$dir/base-image.txt" ] && { echo '```'; cat "$dir/base-image.txt"; echo '```'; }
    if [ -f "$dir/smoketest-$ed.txt" ]; then
      echo "### boot test (QEMU virtual X96 Mini)"; echo '```'; cat "$dir/smoketest-$ed.txt"; echo '```'
      cp "$dir/smoketest-$ed.txt" "$d/"
    fi
    [ -f "$dir/screen-$ed.png" ] && { cp "$dir/screen-$ed.png" "$d/"; echo "Screenshot: [screen-$ed.png](screen-$ed.png)"; }
    [ -f "$dir/serial-$ed.log" ] && cp "$dir/serial-$ed.log" "$d/"
    log="$(ls "$dir"/build-image-*.log 2>/dev/null | head -n1)"
    if [ -n "$log" ]; then
      echo "### errors"; echo '```'
      grep -nE '::error::|^E: |error:|Error |FAILED|WARNING' "$log" | grep -v 'dpkg: warning' | tail -40
      echo '```'
      echo "### last 150 lines"; echo '```'; tail -150 "$log"; echo '```'
      cp "$log" "$d/"
    fi
  done
} > "$d/STATUS.md"
cd "$d"
git init -q && git checkout -q -b build-status
git config user.name "x96os-builder"; git config user.email "actions@users.noreply.github.com"
git add -A && git commit -qm "Build ${GITHUB_RUN_NUMBER}: build=${BUILD_RESULT} release=${RELEASE_RESULT}"
git push -qf "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" build-status
exit 0
