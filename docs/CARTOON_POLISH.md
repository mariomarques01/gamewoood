# v0.5.0 — cartoon geometry and clearer combat

This pass replaces the block captain and capsule aliens with articulated,
rounded cartoon characters. Shared chamfered meshes use flat normals and real
bevel faces; geometry/material caches keep repeated pieces reusable. Repeated
static art is batched using MultiMesh, keeping physics bodies and independently
visible objective markers outside the batches. The captain
has boots, knee pads, pouches, shoulder plates, visor, backpack and a layered
blaster. Legs/arms animate during running/jumping/aiming; muzzle geometry reacts
to firing. Green aliens have antennae and feet; purple troopers carry armor and
plasma weapons. Colliders remain the existing lightweight capsules.

The base uses chamfered structural pieces, recessed windows and mullions,
facade panels/cornices, an original winged emblem, watchtower cabins/braces,
perimeter columns, workshop canopy and service bay. Warm sunlight and one 1024px
directional shadow map add depth. There are no per-lamp shadow maps or expensive
post-processing effects. The diagonal camera moves toward the concept's isometric
presentation. Joystick directions and keyboard movement are mapped through the
camera's horizontal basis, preserving screen-relative controls and independent aim.
The collision-respecting navigation test converts its waypoints accordingly.

The jump action is a drawn arrow with a ground line; its touch target and
third-pointer routing are unchanged. Airborne state dims the arrow. Damage flash
is reduced so it no longer washes out the entire scene as strongly.

Gameplay: first enemy arrives after five seconds, spawn interval initially 4.8s
and gradually falls to 3s. Melee attacks warn for 0.42s and plasma attacks for 0.55s,
with an expanding red ring. Leaving melee reach during the warning avoids damage.
Hits interrupt enemy wind-up. Contact damage is 8 with 1.1s between attacks;
player damage immunity lasts 0.8s. Touch aiming adds soft assistance within about
20 degrees and 14m, testing world occlusion so it does not assist through buildings.
A brief push on receiving close-range damage creates separation. Desktop aiming
remains the world-plane mouse target.

Validation extends existing physical movement/jump/combat/mission tests with icon
presence, articulated model, camera-relative input, soft aim assistance and a
warned attack that misses when the player escapes. Ten-enemy stress and the full
base traversal remain required. Browser screenshots cover desktop, portrait and
landscape, three touch pointers, firing, jump and pause/resume. Physical iPhone
Safari and sustained device FPS are still release checks; CI is not a phone benchmark.
