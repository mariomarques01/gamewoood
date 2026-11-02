# PROJECT: DEADLIGHT

Original cartoon 3D twin-stick shooter, Godot **4.3 stable**, GDScript,
Compatibility renderer (WebGL 2). Captain Tranco defends a coastal military base.

Play: https://mariomarques01.github.io/gamewoood/

Open `project.godot` with Godot 4.3 and run the configured `scenes/main.tscn`.
Desktop: WASD/arrows, hold left mouse to aim/fire, Space to jump, Escape to pause.
Mobile: drag the left stick to move and the right stick to aim/fire simultaneously.
Use the arrow action with a third finger while moving/aiming.
A 24-round magazine reloads automatically. Stand near the current green objective
for three seconds while no alien is within five metres. Complete arsenal,
helipad and communications to win. Restart is available after victory/defeat.

## Validation and publication

See [compact HUD and research](docs/COMPACT_HUD_RESEARCH.md), [cartoon polish](docs/CARTOON_POLISH.md), [HUD and jump changes](docs/HUD_AND_JUMP.md), [recovery diagnosis](docs/RECOVERY.md) and [architecture/status](docs/ARCHITECTURE.md).
Run `tools/validate.sh --export` with official Godot 4.3, an OpenGL display or Xvfb,
then `python3 tests/web_smoke.py --directory build/web` with Playwright installed.
PRs run the same checks. A single workflow `.github/workflows/deploy-web.yml`
deploys main only after runtime, export and browser checks pass.

This is a playable procedural prototype. Real iPhone/Safari and Android device
validation, native signing/exports, profiling and production art remain necessary.

Combat supplies drop every third elimination. Five quick kills trigger a four-second
TRANCO TOTAL boost. Pause to see the complete objective list and elimination count.
