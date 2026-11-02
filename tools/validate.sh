#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p build/logs
python3 tests/audio_assets.py
run_checked() {
  local log="$1"
  shift
  "$@" 2>&1 | tee "$log"
  if grep -Eq 'SCRIPT ERROR:|(^|[[:space:]])ERROR:' "$log"; then
    echo "Godot reported errors despite its exit status" >&2
    exit 1
  fi
}
"$GODOT_BIN" --version | grep -q '^4\.3\.stable\.'
run_checked build/logs/import.log "$GODOT_BIN" --headless --editor --path . --quit
DISPLAY_RUNNER=()
if [[ -z "${DISPLAY:-}" ]]; then DISPLAY_RUNNER=(xvfb-run -a); fi
run_checked build/logs/smoke.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/district_smoke.gd
grep -q 'DEADLIGHT_SMOKE_OK' build/logs/smoke.log
run_checked build/logs/audio.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/audio_smoke.gd
grep -q 'DEADLIGHT_AUDIO_OK' build/logs/audio.log
run_checked build/logs/arcade.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/arcade_smoke.gd
grep -q 'DEADLIGHT_ARCADE_OK' build/logs/arcade.log
run_checked build/logs/navigation.log timeout 90 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/navigation_smoke.gd
grep -q 'DEADLIGHT_NAVIGATION_OK' build/logs/navigation.log
if [[ "${1:-}" == '--export' ]]; then
  mkdir -p build/web
  run_checked build/logs/export.log "$GODOT_BIN" --headless --path . --export-release Web build/web/index.html
  test -s build/web/index.html
  test -s build/web/index.pck
  test -s build/web/index.wasm
  touch build/web/.nojekyll
fi
