# District 1 recovery — Godot 4.3 / v0.2.2

## Root cause

Main commit `43be975` attaches `district_one.gd` to `scenes/main.tscn`, but
`var chase := player.global_position - alien.global_position` cannot be inferred
in Godot 4.3: iteration over `enemies.duplicate()` loses the typed element.
The script fails to load, so its `_ready`, `_process` and `_input` never run.
The static scene still renders the old ground and uncolored capsule.

The successful Actions run `41361395698` contains the same parse errors in both
import and export logs. Godot returned zero and wrote HTML despite those errors.
There were also two independent Pages deployment workflows. Browser cache was
not needed to reproduce the reported failure.

## Fix and regression protection

- Explicit `Vector3` annotation at the failing expression; visible v0.2.2 HUD.
- `tools/validate.sh` pins 4.3, rejects Godot error logs regardless of exit code,
  instantiates the real main scene and verifies map construction, mission markers,
  process/spawning, camera, movement and independent simultaneous touch events.
- Runtime test uses a real OpenGL display (`xvfb-run` in CI). Godot 4.3's dummy
  headless renderer emits null-mesh errors while freeing procedural meshes;
  do not suppress these errors globally.
- `tests/web_smoke.py` serves and launches the actual export in Chromium at
  desktop and mobile viewport sizes, requires the GDScript ready sentinel,
  rejects script/browser exceptions and captures screenshots/console logs.
- One CI workflow validates PRs and only deploys main after runtime, export and
  browser checks pass. Evidence is retained as an Actions artifact.
- Single-threaded Web templates explicitly selected; no COOP/COEP dependency
  for ordinary Pages hosting. PWA/service-worker caching remains disabled.

## Reproduce

```sh
GODOT_BIN=/path/to/Godot_v4.3-stable_linux.x86_64 tools/validate.sh --export
python3 -m pip install playwright==1.58.0
python3 -m playwright install chromium
python3 tests/web_smoke.py --directory build/web
# Or test the deployed artifact:
python3 tests/web_smoke.py --url https://mariomarques01.github.io/gamewoood/
```

Set `CHROMIUM_BIN` to use an existing Chromium installation. A running X display
can be used via `DISPLAY`; otherwise install Xvfb for the native runtime test.
Browser mobile emulation does not certify physical iPhone/Safari operation,
Android/iOS exports, performance, or completion of the later gameplay phases.
The current map remains a greybox; prototype combat and missions need further work.
