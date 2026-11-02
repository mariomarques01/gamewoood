# v0.6.0 — less HUD, more playing field

## Research and adaptation

Sources consulted on 2026-11-02:

- [Gameloft's Zombiewood gameplay support](https://gameloft.helpshift.com/hc/en/80-zombiewood/section/578-gameplay/): objectives can be reviewed on pause, defeated enemies can drop ammunition, and consecutive eliminations feed a combo system.
- [Gameloft's game description](https://www.mkt-web.gameloft.com/m/en/game/zombiewood/): dual-stick action and cartoon presentation. Search result was available; opening this legacy marketing page timed out.
- [Pocket Gamer's 2012 review](https://www.pocketgamer.com/game-reviews/zombiewood-review-entertaining-but-ultimately-forgettable/): comfortable independent move/fire controls, but crowded supplementary UI.

These are design references, not copied assets or a claim that DEADLIGHT reproduces
any particular release of Zombiewood. Current Gameloft support also covers the
newer game. We specifically avoid adding its currency/shop widgets to combat.

## Interface

The former portrait stack ended at 318 logical pixels. It now ends at 106: a
190x46 health pill and one 34-high objective strip. No portrait/name block,
operation subtitle, permanent kill counter, or joystick captions during action.
Ammunition is a 134x36 card between the lower sticks. Health and current task stay
readable; full objectives, life details and eliminations move to the pause panel.
Progress appears only during activation or contest. Navigation shows only distance,
and pickups, sequence and checkpoint notices expire rather than adding new panels.
Touch exclusion at the top shrinks with the HUD, restoring usable movement space.
Automated assertions bound HUD height and check portrait resize/overlap.

## Original arcade loop

- Every third elimination drops a supply (max four simultaneously), preferring
  health while below 80 HP. Health restores 20; ammo fills the 24-round magazine
  and cancels reload. Nearby supplies attract gently, expire after 14s and collect
  once. They cannot revive a defeated player.
- Five kills with no gap greater than four seconds trigger TRANCO TOTAL for four
  seconds: projectile damage 25 -> 37.5 and shot interval .16 -> .12s. The sequence
  resets/boost expires. These balance values are DEADLIGHT choices.
- Completing each of the first two objectives restores up to 15 HP and ammunition
  once, giving breathing room between short combat goals. A brief notice confirms it.

## Base art and checks

The supplied coastal-base concept guides a security gate and striped barriers,
a parked supply rover with wheels/cabin/cargo, side windows/service details,
rounded foliage, subtle asphalt grain and less intrusive objective rings/beacons.
Physics colliders and repeat-piece instancing remain. Full traversal verifies
that added structures do not block any of the three mission routes.

`tests/arcade_smoke.gd` validates automatic collection, single use, reload refill,
sequence/boost damage/fire rate, expiry, one-time checkpoint reward and no revival.
Existing runtime, ten-enemy stress, camera-relative input, three-pointer jump,
mission traversal, victory/defeat, pause/restart and actual Web export/browser checks
remain. Viewport emulation is not physical iPhone/Safari or a phone FPS measurement.
