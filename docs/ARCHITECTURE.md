# Bairro 1 v0.3.0 — playable prototype

## Responsibilities

| Script | Responsibility |
| --- | --- |
| district_one.gd | Scene assembly, win/lose, pause/restart, signals |
| district_map.gd | Independent 3D meshes, static collisions, cached materials |
| player.gd | Movement, aim plane, cartoon Captain Tranco, damage entry point |
| camera_controller.gd | Smoothed elevated follow camera |
| mobile_controls.gd | Two independent pointer IDs, dead zone, visible sticks |
| weapon_system.gd | Fire interval, 24-round magazine, automatic reload |
| projectile.gd | Segment ray collisions (walls/enemies/player), damage, lifetime |
| health_component.gd | Health signals, damage intervals, death |
| enemy_controller.gd | Green melee / purple plasma enemies, local obstacle steering |
| enemy_spawner.gd | Validated spawn points, distance checks, cap of ten enemies |
| mission_manager.gd | Sequential proximity objectives, progress, contested areas |
| hud.gd | Life/ammo/kills, objective, progress, directional marker, overlays |
| save_manager.gd | Best kill count and district completion in user://deadlight.cfg |

Physics collision bits: world=1, aliens=2, player=4. Projectiles raycast their
entire travelled segment, preventing tunnelling and blocking shots at buildings.
The melee attack has a time interval; health has short damage immunity, independent
of frame rate. Enemy steering is local, not a full pathfinding solution; complex
future maps should add a baked navigation mesh. Enemies sleep behaviorally beyond
38m, shots expire, spawning is bounded. Shared map materials avoid duplicates.

The old static 30m fallback ground was removed after recovery tests were added:
it overlapped the generated 58m map and hid roads. Existing map construction was
extracted into its own script and extended, rather than discarding the project.
HQ, arsenal, workshop, radar, watchtowers, road paint, helipad, helicopter,
vegetation, rocks and sea are independent lightweight geometry. No concept art is
used as a background. Primitive art and local steering are deliberate prototype
limits. The helicopter is parked geometry; flight is not implemented.

## Tests and limits

`district_smoke.gd` instantiates the actual scene and exercises startup, spawning,
simultaneous input, movement, follow camera, automatic firing, projectile damage,
wall blocking, player damage interval, proximity/progress on all missions,
victory/defeat, pause and restart. Browser smoke launches the exported release
with desktop/mobile viewport sizes, checks the GDScript version sentinel, rejects
script/browser errors, and captures evidence. Browser emulation is not a physical
multitouch or Safari certification. Automated mission tests use controlled positions
and time steps; they do not prove a human can finish every run under enemy pressure.

Outstanding release gates: physical iPhone/Safari and Android tests, browser safe
area checks on real notches/toolbars, native Android/iOS presets/signing, sustained
FPS/memory measurements on target phones, audio, richer animation and production
cartoon art. No 60 FPS claim is made from software-rendered CI. Save persistence
may be unavailable in restrictive/private browser modes.
