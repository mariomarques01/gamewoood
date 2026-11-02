# v0.10.0 — pistol, machine gun and stage completion

## References and scope

The user supplied two Zombiewood gameplay images: a weapon selector and a scene
completion celebration with a character, rewards and a large completion title.
The linked video is https://www.youtube.com/watch?v=6ELPAk2W81I ; fetching it in
this environment failed, so this change does not claim a full viewing. The supplied
images guide the layout and arcade feedback. All 3D props, UI drawings and balance
rules here are DEADLIGHT's own; no Zombiewood media is shipped.

## Arsenal

Resource definitions live in resources/weapons and share WeaponSystem:

| Weapon | Magazine | Damage | Interval | Reload | Spread |
| --- | ---: | ---: | ---: | ---: | ---: |
| Pistol | 12 | 45 | .30s | .90s | none |
| Machine gun | 24 | 25 | .12s | 1.20s | ±.018 radians |

The machine gun is initially equipped. Two icon buttons above the movement stick
select directly; keys 1/2 select, Q cycles, R reloads. Each weapon retains its own
magazine and in-progress reload. Holstered reloads advance normally, but switching
never refills ammunition or clears the shared firing cooldown. Changing weapon
requires at least .18s before the next shot. Ammo pickups refill the selected gun;
mission checkpoints refill both. TRANCO TOTAL applies 1.5x damage and .75x interval
to either gun. Pause, portrait and finished runs block selection.

Both gun models are constructed once and toggled, with distinct silhouettes,
muzzle colors and HUD icons. The machine gun reuses curated CC0 blaster samples
with lower gain and pitch rather than introducing harsh placeholder bleeps. The
v0.8 mixer, limiter and 12-voice budget remain. Projectile tip/tracer meshes are
shared. Impact sparks use six instances per burst, at most 12 bursts, free after
.28s, and do not cast shadows. Existing alien blood/burst and canister FX remain.

## Completion and save policy

The same three ordered mission triggers end the phase. Victory stops combat,
clears projectiles, deactivates pending canisters, moves the camera toward the
Captain and animates a celebration with 40 instanced confetti pieces. Confetti
is released after four seconds. The result report shows objectives, eliminations,
active game time, collected credits, medals and an animated reward counter.
The replay button and Enter start a clean playable run without waiting for the
counter animation. No unavailable second district is presented as playable.

A completed run earns one medal; 12 kills and finishing with 50+ health each add
one more. Completion credits are 100 + 25 per extra medal (100–150). Collected
credits, including the existing optional kill bonus, are counted once separately.
Defeat retains collected credits but grants no completion bonus or medal.
`ended` guards the reward/save and late kill signals. SaveManager preserves the
best medal count with a backward-compatible default for older progress files.

## Verification

- Existing combat, ten-enemy stress, sound/mute, arcade, chain reactions and real
  collision-respecting traversal to all three objectives remain required.
- arsenal_finale_smoke.gd exercises keyboard and three-pointer switching, visible
  gun/HUD changes, separate magazines, holstered reloads, anti-refill/cooldown,
  actual pistol and automatic shots, FX limits/cleanup, all three mission triggers,
  rewards/save/idempotency, final camera, mobile result bounds, touch replay and
  defeat without a completion bonus. Native result screenshots are inspected.
- The normal Web export tests real keys and weapon touches while the sticks are
  held, movement, jump, actual canister shots, rotation and measured audio/mute.
- export_finale_fixture.py copies the production sources to a temporary project
  and exports a separate QA scene. It deterministically completes the actual
  MissionManager triggers with controlled test data. web_finale.py renders the
  actual results in WebGL, reads the saved ConfigFile reward, checks duplicate
  completion protection, and touches replay back into the real main scene.
  This is a component/integration fixture, not a claim of playing the full level
  manually in Safari. It is exported to build/web-finale; Pages uploads only
  build/web. No fixture or completion cheat is enabled in the published game.

Official Godot 4.3 / Compatibility exports are required. Mobile viewport emulation
and software rendering do not certify physical iPhone/Android FPS or touch/speaker
behavior; device validation remains necessary.
