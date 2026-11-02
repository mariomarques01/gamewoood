# v0.9.0 — tactical explosions and readable combat

## References and adaptation

Consulted on 2026-11-02:

- [Gameloft: Combo Gauge](https://gameloft.helpshift.com/hc/en/80-zombiewood/faq/3708-what-does-the-combo-gauge-do/): consecutive kills feed temporary combat advantages, with a character aura. This support page describes a newer edition; DEADLIGHT does not claim identical rules across editions.
- [Pocket Gamer's 2012 review](https://www.pocketgamer.com/game-reviews/zombiewood-review-entertaining-but-ultimately-forgettable/): comfortable independent move/fire controls, short objectives and a warning about crowded UI.
- The user's gameplay images show large, temporary kill feedback, independent sticks and readable enemy/drop effects.

DEADLIGHT keeps its existing five-kill / four-second boost and displays its remaining
life with a short-lived combo meter, plus a cyan ring around Captain Tranco during
boost. The existing kill popup is reused; no new permanent top row. Duplicate
sequence toast messages are removed. Energy canisters are an original tactical
addition, not a claim verified in the referenced Zombiewood footage or copied art.

## Gameplay and art

Six orange/cyan energy props sit beside combat routes. Two normal 25-damage shots
arm a 40-HP canister, with a blinking 4.5m danger ring and a 0.65s fuse. Detonation
damages visible enemies with distance falloff, arms other exposed canisters and
can hurt the player for 20 HP, subject to normal invulnerability. Walls block both
blast damage and chain triggering. Enemies go through their normal elimination,
combo, drop and mission accounting. Props are solid until destroyed and reset
when the district restarts.

The blast uses a brief warm core, cyan shockwave and shrinking low-poly smoke;
no dynamic lights, screen-wide flash or full-screen postprocessing. At most six
blast visuals coexist and each frees itself after 1.2s. A nearby blast causes a
small, 0.24s camera impulse without accumulated drift. Dynamic props are built
after static batching so their meshes remain independently destructible.

Enemies now show a brief health strip after a nonfatal hit. Knockback gets a real
collision-respecting movement step before pursuit resumes; previously the next AI
frame overwrote its velocity. Supplies check line of sight before attraction or
collection, preventing credits and health from travelling through walls.

## Validation

`impact_smoke.gd` runs actual projectile hits, fuse timing, chain reactions, normal
kill/drop accounting, player damage, wall protection, blocked/clear pickup paths,
knockback displacement, combo/aura expiry and bounded effect cleanup. It verifies
all six props do not overlap solid map geometry and saves combat/boost screenshots.
Existing traversal checks must still reach every objective. The full Godot 4.3
runtime suite and Web browser checks remain deployment gates, including multitouch,
rotation and the v0.8 audio/mute checks.

No physical iPhone/Android FPS or subjective sound validation is implied by native
software rendering or emulated mobile input. Production models and real-device
profiling remain future work.
