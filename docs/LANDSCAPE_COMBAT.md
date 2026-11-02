# v0.7.0 — landscape action and combat feedback

The three user-supplied Zombiewood screenshots guide the information hierarchy and
control appearance. No separate video file or 3D model was accessible in this turn.
All implementation/assets remain original DEADLIGHT geometry and UI drawings.

## Horizontal play

Portrait shows a rotate-device panel and pauses gameplay, preventing damage while
turning the phone. Landscape automatically resumes only an orientation pause;
a user's manual pause survives rotation. The fullscreen button requests browser
fullscreen and orientation lock from a user gesture where supported. iPhone Safari
may require manually turning the device; fullscreen/orientation APIs cannot be
promised across browsers. No CSS-rotated canvas or remapped touch hack is used.

The landscape HUD has a pause button, heart/red health bar, small objective and
credit cards, an original blaster/ammo indicator and a compact optional kill target.
A fading kill-chain callout appears briefly at the side. Details stay in pause.
The two sticks use layered translucent discs, rim highlights, shadow and a dark
raised-looking thumb cap. Movement/aim pointer ownership and the third jump pointer
are preserved. These are 2D drawings, without extra graphics assets or dependencies.

## Hits, enemy explosions and alien blood

The blaster briefly flashes at its muzzle. Enemy defeat now emits an expanding
shock ring and 18 ballistic fragments drawn in a MultiMesh. An irregular green or
purple alien blood splat remains briefly on the floor. Effects do not inflict area
damage, block paths or create physical body parts. Fragments disappear after .8s;
the stain shrinks after 6s and the whole effect expires at 8s. At most ten effects
exist simultaneously. This is stylized alien combat, not realistic anatomy.

## Drops and optional objective

Each eliminated alien drops a collectible worth five credits, subject to a shared
12-item ceiling. Existing health/ammo drops remain; every eighth kill can drop a
four-second power boost. Tokens rotate/bob and attract toward the captain nearby.
Single collection guards prevent repeated credit or power rewards. Credits earned
in the run are stored once on victory/defeat alongside existing progress. An
optional 12-alien challenge awards 25 credits once and does not gate the three
main base objectives or force grinding before victory.

## Validation

Runtime tests cover burst count, blood, effect expiry/budget, credit single use,
power pickup, 12-alien reward, portrait pause, landscape recovery and preservation
of manual pause, alongside existing combat, all objective paths and three-pointer
jump. The actual release Web export is checked in desktop and landscape phone
viewports. The portrait browser case must show the rotate prompt, then rotate into
landscape before exercising controls, fire, jump and pause/resume.

Physical iPhone/Safari, native Android/iOS builds and sustained phone FPS remain
unverified. The browser emulation and effect budget checks are not phone benchmarks.
