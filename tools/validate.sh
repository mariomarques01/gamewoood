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
"$GODOT_BIN" --version | grep -q '^4\.6\.3\.stable\.'
run_checked build/logs/import.log "$GODOT_BIN" --headless --editor --path . --quit
DISPLAY_RUNNER=()
if [[ -z "${DISPLAY:-}" ]]; then DISPLAY_RUNNER=(xvfb-run -a); fi
run_checked build/logs/start-menu.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/start_menu_smoke.gd
grep -q 'DEADLIGHT_START_MENU_OK' build/logs/start-menu.log
run_checked build/logs/smoke.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/district_smoke.gd
grep -q 'DEADLIGHT_SMOKE_OK' build/logs/smoke.log
run_checked build/logs/audio.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/audio_smoke.gd
grep -q 'DEADLIGHT_AUDIO_OK' build/logs/audio.log
run_checked build/logs/arcade.log timeout 45 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/arcade_smoke.gd
grep -q 'DEADLIGHT_ARCADE_OK' build/logs/arcade.log
run_checked build/logs/impact.log timeout 60 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/impact_smoke.gd
grep -q 'DEADLIGHT_IMPACT_OK' build/logs/impact.log
run_checked build/logs/arsenal-finale.log timeout 75 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/arsenal_finale_smoke.gd
grep -q 'DEADLIGHT_ARSENAL_FINALE_OK' build/logs/arsenal-finale.log
run_checked build/logs/navigation.log timeout 180 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/navigation_smoke.gd
grep -q 'DEADLIGHT_NAVIGATION_OK' build/logs/navigation.log
run_checked build/logs/evolution.log timeout 90 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/evolution_smoke.gd
grep -q 'DEADLIGHT_EVOLUTION_OK' build/logs/evolution.log
run_checked build/logs/hud-reference.log timeout 90 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/hud_reference_smoke.gd
grep -q 'DEADLIGHT_HUD_REFERENCE_OK' build/logs/hud-reference.log
run_checked build/logs/neighborhood.log timeout 90 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/neighborhood_smoke.gd
grep -q 'DEADLIGHT_NEIGHBORHOOD_OK' build/logs/neighborhood.log
run_checked build/logs/rendering.log timeout 90 "${DISPLAY_RUNNER[@]}" "$GODOT_BIN" --rendering-method gl_compatibility --audio-driver Dummy --path . --script tests/rendering_smoke.gd
grep -q 'DEADLIGHT_RENDERING_OK' build/logs/rendering.log
run_checked build/logs/camera-recovery.log timeout 15 "$GODOT_BIN" --headless --audio-driver Dummy --path . --script tests/camera_recovery_smoke.gd
grep -q 'DEADLIGHT_CAMERA_RECOVERY_OK' build/logs/camera-recovery.log
if [[ "${1:-}" == '--export' ]]; then
  mkdir -p build/web
  run_checked build/logs/export.log "$GODOT_BIN" --headless --path . --export-release Web build/web/index.html
  test -s build/web/index.html
  test -s build/web/index.pck
  test -s build/web/index.wasm
  python3 tools/prepare_pwa.py build/web
  touch build/web/.nojekyll
  GODOT_BIN="$GODOT_BIN" python3 tools/export_finale_fixture.py
  GODOT_BIN="$GODOT_BIN" python3 tools/export_render_fixture.py
fi
