# Bairro 1 v0.4.0 — mobile HUD, jump and base art pass

The original DEADLIGHT interface now uses an arcade military HUD: Captain Tranco
portrait, segmented health, separate blaster/ammo/kill card, objective/progress
panel, outlined dual sticks, jump action and a readable pause/result panel.
It is inspired by the information hierarchy of mobile twin-stick shooters,
including Zombiewood, without copying its artwork or branding.

Landscape uses a 960x540 UI baseline; portrait uses 540x960 with expanded height
for taller phones. This avoids shrinking all controls into the former 1280-wide
portrait canvas. Layout recalculates when the browser changes size or orientation.
Browser toolbars remain outside the canvas; physical Safari safe-area validation
remains necessary. The camera follows the player's ground position, so jumping
moves the character rather than bouncing the camera vertically.

Jump: Space on desktop, PULAR button on touch devices. A separate third pointer
triggers jump without claiming either stick pointer. Gravity is 22 m/s², initial
jump velocity 8 m/s (roughly 1.45 m height and 0.73 s airborne on flat ground).
Ground checks prevent double jumps; a short input buffer and lock prevent duplicate
touch/UI activation. Lateral movement and firing continue in the air. Jumping is
physical: low obstacles can be cleared; tall walls still collide. Projectiles keep
their physical height, so shots fired high in the air can pass over ground enemies.
Melee requires close vertical proximity. Falling off the island returns the captain
to the last safe ground position with a health penalty.

The supplied base concept guides the next art iterations. This pass adds rooftop
helipad ring/H, parapets and beacons, HVAC, facade columns, neon entry trim,
arsenal shutters, crate hardware, lamps and layered low-poly foliage. Existing
mission locations and collision-respecting routes remain in place. These are
lightweight independent meshes, not a concept-image backdrop or final assets.

Regression coverage adds physical jump/landing, no double jump, independent third
touch with both sticks held, Space in the exported browser game, and portrait
390x844 in addition to desktop and landscape phone dimensions. Existing combat,
stress, objective traversal, defeat/victory, pause/restart and export checks remain.
